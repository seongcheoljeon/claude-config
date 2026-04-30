---
name: defines
description: Every important #define from Shared/*.h and a few Private headers. Use when checking constants/bit flags.
verified-against: UE 5.7.4 @ commit 260bb2e1c561
verification: full (all values copied directly from Shared/*.h)
---

# Defines & Bit Flags

## `Public/Platform.ush`

### `FEATURE_LEVEL_*`

```hlsl
#define FEATURE_LEVEL_ES2_REMOVED  1
#define FEATURE_LEVEL_ES3_1        2   // Mobile (GLES3.1, Metal mobile)
#define FEATURE_LEVEL_SM3          3
#define FEATURE_LEVEL_SM4          4
#define FEATURE_LEVEL_SM5          5   // DX11 / Vulkan baseline
#define FEATURE_LEVEL_SM6          6   // DX12 / Vulkan + RT, mesh shader
#define FEATURE_LEVEL_MAX          7
```

### `PLATFORM_GPU_ARCH_*` (16-bit, vendor in high nibble)

```hlsl
0x0000  UNKNOWN
0x1000  AMD       0x1010=GCN_1, 0x1020=GCN_2, 0x1030=GCN_3, 0x1040=GCN_4, 0x1050=GCN_5
                  0x1110=RDNA_1, 0x1120=RDNA_2, 0x1130=RDNA_3 (LATEST)
0x2000  NVIDIA    0x2010=Kepler, 0x2020=Maxwell, 0x2030=Pascal, 0x2040=Volta, 0x2050~=Turing+
0x3000  Intel
0x4000  ARM (Mali)
0x5000  Apple (M-series)
```

## `Private/ShadingCommon.ush`

### `SHADINGMODELID_*` (low 4 bits of GBuffer custom-data byte)

```hlsl
#define SHADINGMODELID_UNLIT                0
#define SHADINGMODELID_DEFAULT_LIT          1
#define SHADINGMODELID_SUBSURFACE           2
#define SHADINGMODELID_PREINTEGRATED_SKIN   3
#define SHADINGMODELID_CLEAR_COAT           4
#define SHADINGMODELID_SUBSURFACE_PROFILE   5
#define SHADINGMODELID_TWOSIDED_FOLIAGE     6
#define SHADINGMODELID_HAIR                 7
#define SHADINGMODELID_CLOTH                8
#define SHADINGMODELID_EYE                  9
#define SHADINGMODELID_SINGLELAYERWATER    10
#define SHADINGMODELID_THIN_TRANSLUCENT    11
#define SHADINGMODELID_STRATA              12   // legacy alias for Substrate
#define SHADINGMODELID_SUBSTRATE           13
#define SHADINGMODELID_NUM                 14
#define SHADINGMODELID_MASK                0xF
```

### `SelectiveOutputMask` (high 4 bits)

```hlsl
#define SKIP_CUSTOMDATA_MASK     (1 << 4)
#define SKIP_PRECSHADOW_MASK     (1 << 5)
#define ZERO_PRECSHADOW_MASK     (1 << 6)
#define IS_FIRST_PERSON_MASK     (1 << 6)   // Only when ALLOW_STATIC_LIGHTING=0 (shares bit 6)
#define SKIP_VELOCITY_MASK       (1 << 7)

#define SSS_PROFILE_ID_INVALID   255
#define SSS_PROFILE_ID_PERPIXEL  512
```

### `SHADING_PATH_*`

```hlsl
#define SHADING_PATH_MOBILE      0   // override-defined in mobile compilations
#define SHADING_PATH_DEFERRED    0   // override-defined in deferred compilations
```

## `Shared/SubstrateDefinitions.h`

### Closure tree limits

```hlsl
#define SUBSTRATE_MAX_CLOSURE_COUNT_FOR_CLOSUREOFFSET 8u
#define SUBSTRATE_CLOSURE_OFFSET_BIT_COUNT            4u
#define SUBSTRATE_CLOSURE_OFFSET_BIT_MASK             0xF
#define SUBSTRATE_MAX_CLOSURE_COUNT                   SUBSTRATE_MAX_CLOSURE_COUNT_FOR_CLOSUREOFFSET
#define SUBSTRATE_MAX_OPERATOR_COUNT                  15

#define SUBSTRATE_MAX_SHAREDLOCALBASES_REGISTERS      4
#define SUBSTRATE_PACKED_SHAREDLOCALBASIS_STRIDE_BYTES 4
#define SUBSTRATE_FULLY_SIMPLIFIED_NUM_UINTS          (32/4)
```

### BSDF types

```hlsl
#define SUBSTRATE_BSDF_TYPE_SLAB                0    // standard PBR
#define SUBSTRATE_BSDF_TYPE_VOLUMETRICFOGCLOUD   1
#define SUBSTRATE_BSDF_TYPE_UNLIT                2
#define SUBSTRATE_BSDF_TYPE_HAIR                 3
#define SUBSTRATE_BSDF_TYPE_SINGLELAYERWATER     4
#define SUBSTRATE_BSDF_TYPE_EYE                  5
```

### Operators (closure tree node kinds)

```hlsl
#define SUBSTRATE_OPERATOR_WEIGHT       0
#define SUBSTRATE_OPERATOR_VERTICAL     1   // stacked layers (clear coat)
#define SUBSTRATE_OPERATOR_HORIZONTAL   2   // mixed by area
#define SUBSTRATE_OPERATOR_ADD          3
#define SUBSTRATE_OPERATOR_SELECT       4
#define SUBSTRATE_OPERATOR_BSDF         5
#define SUBSTRATE_OPERATOR_BSDF_LEGACY  6   // UE4-style hardcoded models

#define SUBSTRATE_OPERATOR_SUBUSAGE_NONE 0
#define SUBSTRATE_OPERATOR_SUBUSAGE_UI   1
```

### Tile / output

```hlsl
#define SUBSTRATE_TILE_SIZE                  8     // 8x8 tile classification
#define SUBSTRATE_TILE_SIZE_DIV_AS_SHIFT     3

#define SUBSTRATE_LAYER_DEFAULT_THICKNESS_CM 0.01f
#define SUBSTRATE_MIN_GGX_ROUGHNESS          0.02f
#define SUBSTRATE_MIN_FUZZ_ROUGHNESS         0.02f

#define SUBSTRATE_BASE_PASS_MRT_OUTPUT_COUNT 3
#define SUBSTRATE_SSS_DATA_UINT_COUNT        2
```

## `Shared/NaniteDefinitions.h`

```hlsl
#define NANITE_SUBPIXEL_BITS                 8        // 256 subpixel samples
#define NANITE_SUBPIXEL_SAMPLES              256
#define NANITE_SUBPIXEL_DILATE               0
#define NANITE_LATE_VSM_PAGE_TRANSLATION     1
#define NANITE_VSM_PAGE_TABLE_CACHE_DIM      8

#define NANITE_USE_UNCOMPRESSED_VERTEX_DATA  0
#define NANITE_USE_ANALYTIC_SGGX             0
#define NANITE_USE_STRIP_INDICES             1

#define NANITE_NUM_DEPTH_BUCKETS_PER_BLOCK_BITS 8
#define NANITE_NUM_DEPTH_BUCKETS_PER_BLOCK    256
#define NANITE_CONSTRAINED_CLUSTER_CACHE_SIZE 32

#define NANITE_MAX_CLUSTER_TRIANGLES_BITS    7        // 128 tri/cluster
#define NANITE_MAX_CLUSTER_TRIANGLES         128
#define NANITE_MAX_CLUSTER_VERTICES_BITS     8        // 256 vert/cluster
#define NANITE_MAX_CLUSTER_VERTICES          256
#define NANITE_MAX_CLUSTER_INDICES           384      // = 128 * 3
#define NANITE_MAX_UVS                       4
#define NANITE_MAX_CLUSTER_MATERIALS         64
#define NANITE_MAX_CLUSTER_BONE_INFLUENCES   16
#define NANITE_MAX_VOXEL_ANIMATION_BONE_INFLUENCES 1

#define NANITE_FIXUP_MAGIC                   0x464Eu  // "NF"
#define NANITE_CLUSTER_MIN_EXPECTED_GPU_SIZE_BITS 9

#define NANITE_STREAMING_REQUEST_MAGIC_BITS  6
#define NANITE_ROOT_PAGE_GPU_SIZE_BITS       15       // 32 KB root page
#define NANITE_ROOT_PAGE_GPU_SIZE            32768
```

## `Shared/VirtualShadowMapDefinitions.h`

### Page geometry

```hlsl
#define VSM_LOG2_PAGE_SIZE              7u            // 128x128 page
#define VSM_PAGE_SIZE                   128u
#define VSM_PAGE_SIZE_MASK              127u
#define VSM_LOG2_LEVEL0_DIM_PAGES_XY    7u
#define VSM_LEVEL0_DIM_PAGES_XY         128u          // 128x128 page grid
#define VSM_MAX_MIP_LEVELS              8u
#define VSM_VIRTUAL_MAX_RESOLUTION_XY   16384u        // = 128 * 128
#define VSM_RASTER_WINDOW_PAGES         4u

#define VSM_LOG2_RECEIVER_MASK_SIZE     3u
#define VSM_RECEIVER_MASK_SIZE          8u            // 8x8 receiver mask
#define VSM_RECEIVER_MASK_MASK          7u
#define VSM_RECEIVER_MASK_SUBMASK       3u

#define VSM_PAGE_TABLE_TEX2D_SIZE_X     128u
#define VSM_PAGE_TABLE_TEX2D_SIZE_Y     192u          // 128 + 128/2 (mip space)
```

### Page flags (from `VirtualShadowMapPageAccessCommon.ush`)

These combine **hierarchically via OR**:

```hlsl
#define VSM_FLAG_ALLOCATED                       (1u << 0)
#define VSM_FLAG_DYNAMIC_UNCACHED                (1u << 1)
#define VSM_FLAG_STATIC_UNCACHED                 (1u << 2)
#define VSM_FLAG_DETAIL_GEOMETRY                 (1u << 3)
```

Physical-page-only (NOT for hierarchical lookup):

```hlsl
#define VSM_EXTENDED_FLAG_DYNAMIC_INITIALIZED    (1u << 4)
#define VSM_EXTENDED_FLAG_STATIC_INITIALIZED     (1u << 5)
#define VSM_EXTENDED_FLAG_DYNAMIC_DIRTY          (1u << 6)
#define VSM_EXTENDED_FLAG_STATIC_DIRTY           (1u << 7)
#define VSM_EXTENDED_FLAG_INVALIDATE_DYNAMIC     (1u << 8)
#define VSM_EXTENDED_FLAG_INVALIDATE_STATIC      (1u << 9)
#define VSM_EXTENDED_FLAG_VIEW_UNCACHED          (1u << 10)
```

### Projection flags

```hlsl
#define VSM_PROJ_FLAG_CURRENT_DISTANT_LIGHT      (1u << 0)
#define VSM_PROJ_FLAG_UNCACHED                   (1u << 1)
#define VSM_PROJ_FLAG_UNREFERENCED               (1u << 2)
#define VSM_PROJ_FLAG_IS_COARSE_CLIP_LEVEL       (1u << 3)
#define VSM_PROJ_FLAG_IS_FIRST_PERSON_SHADOW     (1u << 4)
#define VSM_PROJ_FLAG_USE_RECEIVER_MASK          (1u << 5)
#define VSM_PROJ_FLAG_FORCE_CACHE_DY...          (further bits — see header)

#define VSM_PACKED_CLIP_LEVEL_BIAS               1024
```

### Visualize bits

```hlsl
#define VIRTUAL_SHADOW_MAP_VISUALIZE_NONE                  0
#define VIRTUAL_SHADOW_MAP_VISUALIZE_SHADOW_FACTOR         (1<<0)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_CLIPMAP_OR_MIP        (1<<1)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_VIRTUAL_PAGE          (1<<2)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_CACHED_PAGE           (1<<3)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_SMRT_RAY_COUNT        (1<<4)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_CLIPMAP_VIRTUAL_SPACE (1<<5)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_GENERAL_DEBUG         (1<<6)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_DIRTY_PAGE            (1<<7)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_GPU_INVALIDATED_PAGE  (1<<8)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_MERGED_PAGE           (1<<9)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_NANITE_OVERDRAW       (1<<10)
#define VIRTUAL_SHADOW_MAP_VISUALIZE_SHADOW_CASTERS        (1<<11)
```

## `Shared/RayTracingDefinitions.h`

### Shader version + masks

```hlsl
#define RAY_TRACING_SHADER_VERSION              0x500880FC

#define RAY_TRACING_MASK_OPAQUE                 0x01   // reflection/shadow/AO/GI
#define RAY_TRACING_MASK_TRANSLUCENT            0x02
#define RAY_TRACING_MASK_OPAQUE_SHADOW          0x04
#define RAY_TRACING_MASK_TRANSLUCENT_SHADOW     0x08
#define RAY_TRACING_MASK_THIN_SHADOW            0x10   // hair-like
#define RAY_TRACING_MASK_HAIR_STRANDS           0x40   // primary against hair
#define RAY_TRACING_MASK_OPAQUE_FP_WORLD_SPACE  0x80   // 1st-person world-space exclusion
#define RAY_TRACING_MASK_ALL                    0xFF
#define RAY_TRACING_MASK_SHADOW                 (OPAQUE_SHADOW | TRANSLUCENT_SHADOW)

#define RAY_TRACING_SHADER_SLOT_MATERIAL        0
#define RAY_TRACING_SHADER_SLOT_SHADOW          1
#define RAY_TRACING_NUM_SHADER_SLOTS            2

#define RAY_TRACING_MISS_SHADER_SLOT_DEFAULT    0      // sets HitT to "miss"
#define RAY_TRACING_MISS_SHADER_SLOT_LIGHTING   1      // light-radiance miss
#define RAY_TRACING_NUM_MISS_SHADER_SLOTS       2
```

### Limits

```hlsl
#define RAY_TRACING_LIGHT_COUNT_MAXIMUM         256
#define RAY_TRACING_DECAL_COUNT_MAXIMUM         256
#define RAY_TRACING_MAX_ALLOWED_RECURSION_DEPTH 1      // RayGen-only trace
#define RAY_TRACING_MAX_ALLOWED_ATTRIBUTE_SIZE  8      // 2 floats (barycentrics)

#define RAY_TRACING_SHADOWS_TYPE_OFF            0
#define RAY_TRACING_SHADOWS_TYPE_HARD           1
#define RAY_TRACING_SHADOWS_TYPE_SOFT           2

#define RAY_TRACING_SHADOWS_TRANSLUCENCY_TYPE_OPAQUE 0
```

## `Shared/RayTracingPayloadType.h`

Each system declares its own payload to avoid forcing big payloads on minimal RT users:

```hlsl
#define RT_PAYLOAD_TYPE_MINIMAL              (1<<0)   // FMinimalPayload
#define RT_PAYLOAD_TYPE_DEFAULT              (1<<1)   // FDefaultPayload
#define RT_PAYLOAD_TYPE_RAYTRACING_MATERIAL  (1<<2)   // FPackedMaterialClosestHitPayload
#define RT_PAYLOAD_TYPE_RAYTRACING_DEBUG     (1<<3)
#define RT_PAYLOAD_TYPE_DEFERRED             (1<<4)   // FDeferredMaterialPayload
#define RT_PAYLOAD_TYPE_PATHTRACING_MATERIAL (1<<5)   // FPackedPathTracingPayload
#define RT_PAYLOAD_TYPE_LUMEN_MINIMAL        (1<<6)   // FLumenMinimalPayload (small!)
#define RT_PAYLOAD_TYPE_VFX                  (1<<7)
#define RT_PAYLOAD_TYPE_DECALS               (1<<8)
#define RT_PAYLOAD_TYPE_SPARSE_VOXEL         (1<<9)
```

## `Shared/PathTracingDefinitions.h`

### Light flags (bitfield in light scene data)

```hlsl
#define PATHTRACER_FLAG_LIGHTING_CHANNEL_MASK            (7 << 0)
#define PATHTRACER_FLAG_TRANSMISSION_MASK                (1 << 3)
#define PATHTRACER_FLAG_NON_INVERSE_SQUARE_FALLOFF_MASK  (1 << 4)
#define PATHTRACER_FLAG_STATIONARY_MASK                  (1 << 5)   // GPULightmass only
#define PATHTRACER_FLAG_TYPE_MASK                        (7 << 6)
#define PATHTRACING_LIGHT_SKY                            (0 << 6)
#define PATHTRACING_LIGHT_DIRECTIONAL                    (1 << 6)
#define PATHTRACING_LIGHT_POINT                          (2 << 6)
#define PATHTRACING_LIGHT_SPOT                           (3 << 6)
#define PATHTRACING_LIGHT_RECT                           (4 << 6)
#define PATHTRACER_FLAG_CAST_SHADOW_MASK                 (1 << 9)
#define PATHTRACER_FLAG_CAST_VOL_SHADOW_MASK             (1 << 10)
#define PATHTRACER_FLAG_CAST_CLOUD_SHADOW_MASK           (1 << 11)
#define PATHTRACER_FLAG_HAS_RECT_TEXTURE_MASK            (1 << 12)
```

### Instance mask (PT-specific, separate from RT_MASK_*)

```hlsl
#define PATHTRACER_MASK_CAMERA                0x01
#define PATHTRACER_MASK_HAIR_CAMERA           0x02
#define PATHTRACER_MASK_SHADOW                0x04
#define PATHTRACER_MASK_HAIR_SHADOW           0x08
#define PATHTRACER_MASK_INDIRECT              0x10
#define PATHTRACER_MASK_HAIR_INDIRECT         0x20
#define PATHTRACER_MASK_CAMERA_TRANSLUCENT    0x40
#define PATHTRACER_MASK_INDIRECT_TRANSLUCENT  0x80
#define PATHTRACER_MASK_IGNORE                0x00

#define PATHTRACER_SAMPLER_DEFAULT            0
#define PATHTRACER_SAMPLER_ERROR_DIFFUSION    1
```

## Material translator macros

```hlsl
USE_VERTEX_FACTORY_FWD              // includes /Engine/Generated/VertexFactoryFwd.ush
ENABLE_NEW_HLSL_GENERATOR           // new translator path
MATERIAL_LWC_ENABLED                // Large World Coordinates active
UE_DF_FORCE_FP32_OPS                // forces FP32 math when LWC off
TEMPLATE_USES_SUBSTRATE             // FPixelMaterialInputs gets GetFrontSubstrateData()
SUBSTRATE_USE_FULLYSIMPLIFIED_MATERIAL    // FullySimplified path used
NUM_TEX_COORD_INTERPOLATORS         // # texcoord slots in FMaterialPixelParameters
```

## VSM `FVirtualShadowMapHandle` invariant

```hlsl
VSM_MAX_SINGLE_PAGE_SHADOW_MAPS     // ID < this → bIsSinglePageSM = true
                                    // ID >= this → full multi-page (directional, etc.)
0xFFFFFFFFu                         // invalid handle id
```

(Defined in `Shared/VirtualShadowMapDefinitions.h` — exact value varies by build flags.)
