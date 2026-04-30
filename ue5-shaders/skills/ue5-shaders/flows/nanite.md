---
name: flow-nanite
description: Nanite cluster culling → SW rasterizer → visibility buffer → material shading flow.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: partial (file list verified; per-stage entry function names verified for major files)
---

# Nanite Flow — Mesh to Pixel

## Mental model

- Mesh is pre-processed into **clusters** (≤128 tri / ≤256 vert).
- Clusters form a **DAG** with multiple LODs along edges.
- Per frame: **traverse the DAG** to pick the right LOD per cluster, **cull**, then **rasterize**.
- Small triangles → atomic write to **uint64 visibility buffer** (depth + clusterIdx + triIdx) by a compute SW rasterizer. Big triangles → HW rasterizer.
- Pixel material is **resolved later** by reading visibility buffer + cluster data.

## Per-frame pipeline

```
[Streaming] (background)
  NaniteStreaming.usf       — page upload requests from feedback
  NaniteStreamOut.usf
  NaniteScatterUpdates.usf
  NaniteTranscode.usf       — compressed → runtime format

[Cull]
  NanitePrimitiveFilter.usf            — Show/Hide
  NaniteInstanceCulling.usf            — frustum + HZB per instance
  NaniteInstanceHierarchyCulling.usf   — instance BVH/group
  NaniteClusterCulling.usf             — per-cluster LOD selection + frustum + HZB
    └── uses NaniteHierarchyTraversal.ush, NaniteHZBCull.ush

[Rasterize] (compute SW)
  NaniteRasterBinning.usf              — bins clusters by tile
  NaniteRasterizer.usf                 — edge eq → atomic min uint64 → visibility buffer
    └── NaniteWritePixel.ush, NaniteRasterizationCommon.ush
  NaniteRasterClear.usf, NaniteFastClear.usf

[Resolve / Shade]
  NaniteShadeBinning.usf               — per-tile material ID → tile lists per material
  NaniteExportGBuffer.usf              — material shader, runs per material's tiles
    └── reads cluster data → barycentric interp → MaterialTemplate eval → GBuffer

[Shadow]
  NaniteEmitShadow.usf                 — direct VSM page raster

[RT]
  NaniteRayTracing.usf                 — Nanite mesh in BVH (special LOD)
  NaniteRayTrace.ush
```

## Cluster size (verified `Shared/NaniteDefinitions.h`)

```hlsl
NANITE_MAX_CLUSTER_TRIANGLES  = 128   (7-bit index)
NANITE_MAX_CLUSTER_VERTICES   = 256   (8-bit index)
NANITE_MAX_CLUSTER_INDICES    = 384   (= 128 * 3)
NANITE_MAX_UVS                = 4
NANITE_MAX_CLUSTER_MATERIALS  = 64
NANITE_SUBPIXEL_BITS          = 8     (256 subpixel samples)
```

## Visibility buffer encoding

uint64 per pixel via atomic min:

```
[63:32] depth (high bits)
[31:24] cluster sub-index
[23: 0] triangle index in cluster (or packed cluster+tri)
```

Atomic min ensures front-most fragment wins regardless of dispatch order. SW raster never needs ROP.

## SW vs HW raster split

Each cluster picks one path based on screen-space triangle area heuristic:

| Triangle size | Path |
|---------------|------|
| ≤ ~few pixels | SW rasterizer (compute, atomic write) |
| Bigger        | HW rasterizer (mesh shader where supported, classic VS+PS otherwise) |

`NaniteRasterBinning.usf` does the bin.

## Material shading (`NaniteExportGBuffer.usf`)

This is a **material shader pass** — translator-aware:
- includes `MaterialTemplate.ush` + `Nanite/NaniteVertexFactory.ush`
- per-pixel: read visibility buffer → fetch cluster + triangle → interpolate attributes → run material graph → emit GBuffer (or Substrate MRTs)
- runs per material via `NaniteShadeBinning.usf` tile lists → only pixels that need that material

Critical performance lever:
- **WPO** (World Position Offset) in pixel space costs huge register pressure
  → `MaterialTemplate.ush` forces `COMPILER_FORCE_WAVE32_MODE` for Nanite material PS
  → `r.Nanite.ProgrammableRaster.WPODistanceLimit` to disable WPO past N units

## VSM integration

`NANITE_LATE_VSM_PAGE_TRANSLATION = 1`:
- Nanite cluster culling done **once** per view; shadow pages share culling result.
- `NaniteEmitShadow.usf` rasterizes directly into VSM physical pages.

## Skinned Nanite

```
NaniteSkinningUpdateViewData.usf       — bone palette → cluster transform per view
NaniteVertexDeformation.ush
```

## Voxel / Imposter / Tessellation

```
NaniteSVO.ush                — Sparse Voxel Octree (Voxel/ subfolder)
NaniteImposter.ush           — far LOD imposters
NaniteTessellation.ush       — adaptive tess
NaniteDice.ush               — triangle dice/subdivide
NaniteSplit.usf              — cluster split
```

## Debug

| Console | Effect |
|---------|--------|
| `r.Nanite` | global toggle |
| `r.Nanite.Visualize` | viz mode (shader complexity, cluster, etc.) |
| `r.Nanite.Stats` / `NanitePrintStats.usf` | counters |
| `r.Nanite.Streaming.PoolSize` | GPU page pool |
| `r.Nanite.MaxVisibleClusters` | clamp |
| `r.Nanite.ProgrammableRaster` | enable WPO via SW raster |
| `r.Nanite.RayTracedShadows` | RT shadow path |
| `r.Nanite.VSMMeshShaderRasterization` | mesh shader for VSM |

## Common issues

- **Cluster missing past distance**: hierarchy traversal LOD heuristic; check `r.Nanite.MaxPixelsPerEdge`.
- **HZB occlusion eats nearby objects**: HZB is from previous frame; first-frame movements may pop. Check `r.Nanite.OcclusionCull`.
- **Material missing on Nanite mesh**: `NaniteShadeBinning` skipped that material; verify `MaterialUsage_Nanite` flag on the material asset.
- **WPO too expensive**: limit distance, or disable Programmable Raster for that material.
- **VSM pages not invalidating on Nanite anim**: `r.Shadow.Virtual.Cache.GenerateInvalidatingPrims=1`.
