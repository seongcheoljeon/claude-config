---
name: flow-vsm
description: Virtual Shadow Maps page allocation, marking, raster, and projection flow.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (page flag bits, handle struct, definitions header all read directly)
---

# Virtual Shadow Maps (VSM) Flow

## Concept

- Virtual resolution **16384×16384** (or higher) per shadow map.
- Sparse: only **128×128 pages** that screen pixels need are physically resident.
- Directional → multi-level **clipmap** (8 mip levels). Spot/Point → **6-face cubemap** + mips.
- Single-page lights (small/distant) live in a separate ID range (`VSM_MAX_SINGLE_PAGE_SHADOW_MAPS`).
- Nanite is the primary rasterizer; conventional meshes also supported.

## Per-frame pipeline

```
[Mark] which virtual pages do we need?
  VirtualShadowMapPageMarking.usf
  VirtualShadowMapPageMarking.ush
  ──→ requests come from screen pixels via projection sampling

[Cache] reuse pages from previous frame where possible
  VirtualShadowMapCacheLoadBalancer.usf
  VirtualShadowMapCacheGPUInvalidation.usf
  VirtualShadowMapCacheInvalidation.ush

[Build draws] per-page indirect draw commands
  VirtualShadowMapBuildPerPageDrawCommands.usf
  VirtualShadowMapComputeExplicitChunkDrawsViewMask.usf
  VirtualShadowMapPerPageDispatch.ush
  VirtualShadowMapPageOverlap.ush

[Raster] write depth into physical pages
  Nanite path: NaniteEmitShadow.usf  (NANITE_LATE_VSM_PAGE_TRANSLATION = 1)
  Conventional: ShadowDepth*.usf with VSM-aware page binding

[Manage] physical pool defrag / throttle
  VirtualShadowMapPhysicalPageManagement.usf
  VirtualShadowMapThrottle.usf
  VirtualShadowMapCompactViews.usf

[Sample] at deferred lighting time
  VirtualShadowMapProjection.usf
    ├─ VirtualShadowMapProjectionDirectional.ush  (clipmap)
    ├─ VirtualShadowMapProjectionSpot.ush         (cubemap)
    └─ VirtualShadowMapProjectionFilter.ush       (PCF)
  VirtualShadowMapProjectionComposite.usf

[Optional] Screen-space contact shadow boost
  VirtualShadowMapSMRTCommon.ush
  VirtualShadowMapSMRTTemplate.ush
  VirtualShadowMapScreenRayTrace.ush
```

## Constants (verified)

From `Shared/VirtualShadowMapDefinitions.h`:

```hlsl
VSM_PAGE_SIZE                = 128
VSM_LEVEL0_DIM_PAGES_XY      = 128         // 128x128 page grid
VSM_VIRTUAL_MAX_RESOLUTION   = 16384       // 128 * 128
VSM_MAX_MIP_LEVELS           = 8
VSM_RASTER_WINDOW_PAGES      = 4
VSM_RECEIVER_MASK_SIZE       = 8           // 8x8 mask per page
VSM_PAGE_TABLE_TEX2D_SIZE_Y  = 192         // base + mip space (128 + 64)
```

## Page flags (verified bit positions)

Hierarchical (OR-combinable, valid in lookups):

```hlsl
VSM_FLAG_ALLOCATED          (1<<0)
VSM_FLAG_DYNAMIC_UNCACHED   (1<<1)
VSM_FLAG_STATIC_UNCACHED    (1<<2)
VSM_FLAG_DETAIL_GEOMETRY    (1<<3)   // exclude from coarse-page draws
```

Physical-page-only (DO NOT use in hierarchical lookups — see [quirks.md](../quirks.md#vsm-page-flags-are-hierarchical-or-mostly)):

```hlsl
VSM_EXTENDED_FLAG_DYNAMIC_INITIALIZED  (1<<4)
VSM_EXTENDED_FLAG_STATIC_INITIALIZED   (1<<5)
VSM_EXTENDED_FLAG_DYNAMIC_DIRTY        (1<<6)
VSM_EXTENDED_FLAG_STATIC_DIRTY         (1<<7)
VSM_EXTENDED_FLAG_INVALIDATE_DYNAMIC   (1<<8)
VSM_EXTENDED_FLAG_INVALIDATE_STATIC    (1<<9)
VSM_EXTENDED_FLAG_VIEW_UNCACHED        (1<<10)
```

Projection flags:

```hlsl
VSM_PROJ_FLAG_CURRENT_DISTANT_LIGHT     (1<<0)
VSM_PROJ_FLAG_UNCACHED                  (1<<1)
VSM_PROJ_FLAG_UNREFERENCED              (1<<2)
VSM_PROJ_FLAG_IS_COARSE_CLIP_LEVEL      (1<<3)
VSM_PROJ_FLAG_IS_FIRST_PERSON_SHADOW    (1<<4)
VSM_PROJ_FLAG_USE_RECEIVER_MASK         (1<<5)
```

## Handle struct (verified)

`Private/VirtualShadowMaps/VirtualShadowMapHandle.ush`:

```hlsl
struct FVirtualShadowMapHandle
{
    uint Id;
    bool bIsSinglePageSM;
};

// Construction (static factories)
MakeFromId(Id)                  → bIsSinglePageSM = (Id < VSM_MAX_SINGLE_PAGE_SHADOW_MAPS)
MakeFromIdDirectional(Id)       → bIsSinglePageSM = false  (forced; directionals always multi-page)
MakeFromFullIndex(FullIdx)      → Id = FullIdx + VSM_MAX_SINGLE_PAGE_SHADOW_MAPS
MakeInvalid()                   → Id = 0xFFFFFFFFu
MakeOffset(int Offset)          → signed offset on Id
```

## Marking → Caching → Drawing → Sampling — life of a page

```
 Frame N
 ╔════════ Mark (compute) ════════╗
 ║ Screen pixel needs page (X,Y,M) for light L                       ║
 ║   → Page Marking writes:                                          ║
 ║       PageTable[L][M][X,Y].Flags |= VSM_FLAG_ALLOCATED             ║
 ║                                |  (VSM_FLAG_DYNAMIC_UNCACHED if   ║
 ║                                   page wasn't cached this frame)  ║
 ╚═══════════════════════════════════════════════════════════════════╝
 ╔════════ Cache (compute) ════════╗
 ║ CacheLoadBalancer scans page metadata; keeps clean pages from N-1 ║
 ║   → for moving lights: invalidate via CacheGPUInvalidation        ║
 ╚═══════════════════════════════════════════════════════════════════╝
 ╔════════ Build per-page draws (compute) ════════╗
 ║ For each NewlyAllocated page → emit indirect draw commands        ║
 ║   (filtered by VSM_FLAG_DETAIL_GEOMETRY for coarse pages)         ║
 ╚═══════════════════════════════════════════════════════════════════╝
 ╔════════ Raster ════════╗
 ║ Nanite: NaniteEmitShadow runs indirect, writes to physical pool   ║
 ║ Conventional: ShadowDepth* runs indirect with page-aware projection║
 ║   → physical page now contains depth                              ║
 ║   → mark VSM_EXTENDED_FLAG_*_INITIALIZED                          ║
 ╚═══════════════════════════════════════════════════════════════════╝
 ╔════════ Sample (deferred lighting) ════════╗
 ║ For each lit pixel:                                               ║
 ║   handle = FVirtualShadowMapHandle::MakeFromId(LightId)            ║
 ║   page = GetVirtualShadowMapPage(handle, mip, x, y)               ║
 ║   ProjectionDirectional/Spot.ush → PCF filter → shadow factor     ║
 ║   (optional) SMRT screen-space ray for contact shadow             ║
 ╚═══════════════════════════════════════════════════════════════════╝
```

## SMRT — Screen-space Multi-Ray Tracing

When VSM PCF is undersampled (e.g. very thin geometry), SMRT shoots short rays in screen space to fix contact shadow artifacts:

```
VirtualShadowMapSMRTCommon.ush
VirtualShadowMapSMRTTemplate.ush     // template-style code generation
VirtualShadowMapScreenRayTrace.ush
```

`r.Shadow.Virtual.SMRT.RayCountLocal/Directional` for ray budget.

## Visualize

```hlsl
VIRTUAL_SHADOW_MAP_VISUALIZE_VIRTUAL_PAGE        // page address per pixel
VIRTUAL_SHADOW_MAP_VISUALIZE_CACHED_PAGE         // cached vs newly-rastered
VIRTUAL_SHADOW_MAP_VISUALIZE_SMRT_RAY_COUNT      // SMRT cost
VIRTUAL_SHADOW_MAP_VISUALIZE_NANITE_OVERDRAW     // shadow raster overdraw
VIRTUAL_SHADOW_MAP_VISUALIZE_DIRTY_PAGE          // pages re-rendered this frame
VIRTUAL_SHADOW_MAP_VISUALIZE_GPU_INVALIDATED_PAGE
```

`r.Shadow.Virtual.Visualize <bitmask>` to enable.

## Debug pitfalls

- **Acne / shimmer at distance**: clipmap level transition; tweak per-level bias.
- **Pages thrashing**: `r.Shadow.Virtual.Cache=1`, check `VirtualShadowMapStats.usf` output.
- **Directional handle constructed via `MakeFromId` instead of `MakeFromIdDirectional`** → loses mip levels (single-page treatment).
- **OR'ing extended flags into hierarchy queries** → page state corruption. Stick to `VSM_FLAG_*` only.
- **Dynamic objects not casting**: invalidation flag missing; verify `r.Shadow.Virtual.Cache.GenerateInvalidatingPrims=1`.
