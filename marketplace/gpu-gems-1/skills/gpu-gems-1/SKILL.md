---
name: gpu-gems-1
description: GPU Gems 1 (NVIDIA, 2004) 42개 챕터 알고리즘 레퍼런스 라우터. 워터(Gerstner/sine-sum/caustics), 노이즈(Perlin/Voronoi/texture-bombing), 섀도우(Volume/PCF/PSM/Omnidirectional/Soft/Occlusion-Interval), 라이팅(Uberlight/SSS/AO/IBL/Spatial-BRDF), 포스트프로세스(Glow/DoF/ColorCurves/Bicubic/OpenEXR/Filter-Width), 시뮬레이션(Stable-Fluids/Volume/Deformer/Stereogram), GPGPU/Pipeline. 트리거 — "Gerstner wave", "물 시뮬레이션", "Perlin noise", "shadow volume", "PCF", "perspective shadow map", "subsurface scattering", "ambient occlusion", "image-based lighting", "spatial BRDF", "depth of field", "real-time glow", "color grading", "OpenEXR", "texture bombing", "occlusion culling", "Stable Fluids", "volume rendering", "GPGPU", "diffraction". 다루지 않음 — UE5 Engine/Shaders 코드 (→ ue5-shaders), 셰이더 cvar (→ unreal-dev-kb), Houdini Pyro/Gas 적용 (→ gpu-fluid-sim/hdk-reference), C++ RDG 패스 작성 (→ ue5-rdg). 한계 — 2004년 NVIDIA 기준이라 일부 구현 디테일(register combiner, pbuffer, FX Composer, Cg, RenderMan interop)은 obsolete; 알고리즘 아이디어는 현대 API로 재해석 필요.
license: MIT
---

# GPU Gems 1 Reference Router

> NVIDIA의 *GPU Gems: Programming Techniques, Tips, and Tricks for Real-Time Graphics* (2004, Addison-Wesley) 한글 학습 노트 라우터. 챕터별 핵심 개념·수식·HLSL 예시를 즉시 인용 가능.

## 사용 흐름

1. 사용자 질문이 GPU 그래픽스 알고리즘 관련일 때 **아래 라우팅 테이블에서 해당 챕터 식별**
2. `chapters/chXX_*.md`를 직접 읽어 핵심 개념 / 기술 세부 / 수식 / HLSL 코드 인용
3. 답변 시 알고리즘은 GPU Gems 원문 표기를 따르되, **2004년 구현 디테일은 현대 API(D3D12/Vulkan/UE5/Metal)로 재해석**
4. 비슷한 영역의 다른 plugin이 있으면 명시적으로 링크 (예: SSS 알고리즘 → ch16, UE 구현 → `ue5-shaders`)

## 라우팅 테이블 (42 챕터 → 11 그룹)

### Part I. 자연 현상 시뮬레이션

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| 물 표면 파동 | `ch01_water_simulation.md` | Sine-sum, Gerstner wave, 동적 노멀맵 |
| 물 코스틱 | `ch02_water_caustics.md` | Perlin 기반 굴절, 멀티패스 |
| 불 이펙트 | `ch06_fire_vulcan_demo.md` | 애니메이션 스프라이트, heat haze, additive |
| 흔들리는 잔디 | `ch07_waving_grass.md` | Cross quads, 알파 텍스처, 정점 스왑 |
| 회절 | `ch08_simulating_diffraction.md` | Diffraction grating, 파동 이론 |
| 유체 역학 | `ch38_fast_fluid_dynamics.md` | Stable Fluids, advection, semi-Lagrangian *(→ `gpu-fluid-sim` 보강)* |

### Part II. 노이즈 / 프로시저럴

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| Perlin noise | `ch05_perlin_noise.md` | Perlin/Simplex, Hermite 보간 |
| Texture bombing | `ch20_texture_bombing.md` | Voronoi 셀, 의사난수 변형 |

### Part III. 캐릭터 / 피부

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| 피부 셰이딩 | `ch03_skin_dawn_demo.md` | HDR 환경맵, wrap, rim lighting |
| 캐릭터 애니메이션 | `ch04_animation_dawn_demo.md` | Indexed skinning, morph targets, blend shapes |
| Subsurface scattering | `ch16_subsurface_scattering.md` | Wrap lighting, depth-map 흡수, texture-space diffusion |

### Part IV. 섀도우

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| Shadow volume | `ch09_shadow_volume_rendering.md` | 스텐실 기반, geometry-extrusion |
| Shadow map AA | `ch11_shadow_map_antialiasing.md` | PCF (Percentage-Closer Filtering), 4×4 |
| Omnidirectional shadow | `ch12_omnidirectional_shadow_mapping.md` | 큐브맵, dual paraboloid |
| Soft shadow | `ch13_soft_shadows_occlusion_interval_maps.md` | Occlusion interval map |
| Perspective shadow map | `ch14_perspective_shadow_maps.md` | PSM, post-perspective space |

### Part V. 가시성 / 컬링

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| 픽셀당 조명 + 가시성 | `ch15_managing_visibility_per_pixel_lighting.md` | 포털 가시성, scissor clipping, 배치 병목 |
| Occlusion culling | `ch29_occlusion_culling.md` | Occlusion query, 카메라 컬링 |

### Part VI. 라이팅 / 머티리얼 / BRDF

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| Cinematic lighting | `ch10_cinematic_lighting.md` | Uberlight, super-ellipse, shape control |
| Ambient occlusion | `ch17_ambient_occlusion.md` | Bent normal, accessibility, 블러 환경맵 |
| Spatial BRDF | `ch18_spatial_brdfs.md` | Lafortune, 사전 컨볼루션 |
| Image-based lighting | `ch19_image_based_lighting.md` | Localized cube map, Fresnel, sphere-ray 교차 |
| Cinema4D 셰이딩 | `ch34_hardware_shading_cinema4d.md` | Phong, 범프맵, 환경맵 통합 |

### Part VII. 포스트프로세스 / 필터링

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| Real-time glow | `ch21_real_time_glow.md` | Separable convolution, 저해상도 블러 |
| Color controls | `ch22_color_controls.md` | Per-channel curves, 3D color cube |
| Depth of field | `ch23_depth_of_field.md` | Circle of Confusion (CoC), 5가지 기법 비교 |
| High-quality filter | `ch24_high_quality_filtering.md` | Catmull, Mitchell-Netravali bicubic, 3×3 conv |
| Filter width | `ch25_fast_filter_width_estimates.md` | 밉맵 미분, 특수 필터맵 |

### Part VIII. 이미지 포맷 / 프레임워크

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| OpenEXR | `ch26_openexr_image_file_format.md` | Half(16-bit float), 채널 혼합 |
| Image processing FW ⚠️ | `ch27_framework_image_processing.md` | Pull-based DAG, dirty 플래그, pbuffer (legacy) |
| Software rendering | `ch35_leveraging_software_rendering.md` | Render-to-texture, render-to-vertices |

### Part IX. 성능 / 파이프라인 / GPGPU

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| Pipeline performance | `ch28_pipeline_performance.md` | 병목 식별 방법론 |
| Shader interfaces | `ch32_shader_interfaces.md` | illuminate/main 모듈 조합 |
| GPGPU toolkit | `ch37_toolkit_computation_gpus.md` | 스트림 프로세싱 모델 |

### Part X. 볼륨 / 시각화 / 디포머

| 주제 | 챕터 | 핵심 알고리즘 |
|---|---|---|
| Volume rendering | `ch39_volume_rendering.md` | 텍스처 기반 볼륨 |
| Ultrasound viz | `ch40_ultrasound_visualization.md` | 음향 그리드, projective texture |
| Stereogram | `ch41_real_time_stereograms.md` | SIRDS (Single Image RDS) |
| Mesh deformer | `ch42_deformers.md` | Jacobi 풀이, 메시 디포머 |

### Part XI. 레거시 도구 체인 ⚠️

> **2004년 NVIDIA 도구**. 알고리즘 아이디어는 참고하되 구현 디테일은 현대 IDE/API로 대체.

| 주제 | 챕터 | 비고 |
|---|---|---|
| FX Composer 설계 | `ch30_design_fx_composer.md` | 확장 가능 셰이더 IDE — 현재 obsolete |
| FX Composer 사용 | `ch31_using_fx_composer.md` | 워크플로우 가이드 — UE5 Material Editor로 대체 |
| RenderMan 변환 | `ch33_converting_renderman_shaders.md` | RenderMan→Cg 변환 — Cg는 deprecated |
| Shader integration | `ch36_integrating_shaders.md` | 통신 레이어, 데이터 드리븐 — 현대 RHI 추상화로 대체 |

## 응답 원칙

1. **알고리즘 인용은 챕터 표기를 따른다** — "GPU Gems 1, Chapter 16: Real-Time Approximations to Subsurface Scattering"
2. **HLSL/Cg 코드 인용 시 출처 명시** — 챕터 파일에 있는 코드를 그대로 인용 (재구성 금지)
3. **레거시 영역은 명시적으로 경고** — pbuffer, register combiner, FX Composer 관련 답변에는 "현대 API에서는 X로 대체됨" 추가
4. **다른 plugin과 영역 겹치면 명시적 라우팅** — 예: "이 알고리즘 자체는 ch38이지만, UE5 Niagara에서의 구현은 `gpu-fluid-sim` 참조"

## 함께 활성화되면 좋은 plugin

| 시나리오 | 협력 plugin | 본 plugin 역할 | 협력 plugin 역할 |
|---|---|---|---|
| 물/연기/불 시뮬을 UE5/Houdini에 적용 | `gpu-fluid-sim` | ch01, ch02, ch06, ch38 알고리즘 원문 | Stable Fluids/MacCormack/BFECC 현대 구현 |
| GPU Gems 알고리즘을 UE5 셰이더로 이식 | `ue5-shaders` | 알고리즘 원리 + 원본 HLSL | UE5 Engine/Shaders 트리 매핑 |
| 시각화/디버깅 cvar 필요 | `unreal-dev-kb` | 알고리즘 의도 | UE5 cvar/ShowFlag/ViewMode |
| Houdini DSO에 알고리즘 적용 | `hdk-reference` | 알고리즘 원리 | HDK SOP/SIM 패턴 |
| RDG 패스에서 호출 | `ue5-rdg` | 셰이더 알고리즘 | RDG C++ API 작성 |

## 갱신

- GPU Gems 2/3는 별도 plugin (`gpu-gems-2`, `gpu-gems-3`)으로 분리 예정
- 챕터별 한글 학습 노트는 `chapters/`에 위치, 신규 추가 시 본 라우팅 테이블에 행 추가
