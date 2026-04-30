---
name: hdk-reference
description: Houdini HDK (Houdini Development Kit) C++ reference for Houdini 21.0. Use when writing, reviewing, or generating HDK C++ code. Covers DSO entry points, SOP/DM/GUI/SIM/RAY/VEX/COP2/CHOP node patterns, custom primitive pipeline (GEO→GT→GR), viewport render hooks, packed primitives, Mantra procedurals, simulation solvers, VEX custom functions, core API patterns (GA_Handle, RE_Geometry, PRM_Template, Data ID management), and debugging (gdb, valgrind, UT_ASSERT, HOUDINI_DSO_ERROR, crash recovery). Triggers on any Houdini HDK, SOP plugin, viewport hook, custom primitive, HDK debugging, or Houdini C++ code generation request.
---

# Houdini 21.0 HDK Reference

Houdini HDK C++ 코드 작성 시 참조하는 레퍼런스. 공식 HDK 샘플 코드에서 추출한 검증된 패턴만 포함.

## DSO Entry Points

모든 HDK DSO는 카테고리별 진입점 함수를 정의해야 한다. `#include <UT/UT_DSOVersion.h>` 필수.

| 카테고리 | 진입점 함수 |
|---------|-----------|
| SOP | `newSopOperator(OP_OperatorTable*)` |
| DM/GUI | `newRenderHook(DM_RenderTable*)` |
| SIM | `initializeSIM(void*)` + `IMPLEMENT_DATAFACTORY` |
| RAY | `registerProcedural(RAY_ProceduralFactory*)` |
| RAY PixelFilter | `allocPixelFilter(const char*)` |
| VEX | `newVEXOp(void*)` |
| COP2 | `newCop2Operator(OP_OperatorTable*)` |
| CHOP | `newChopOperator(OP_OperatorTable*)` |
| Custom Prim | `newGeometryPrim(GA_PrimitiveFactory*)` |
| OBJ | `newSopOperator(OP_OperatorTable*)` |
| ROP | `newDriverOperator(OP_OperatorTable*)` |
| DM Mouse | `DMnewEventHook(DM_EventTable*)` |

---

## SOP Patterns

### 레거시 패턴 (SOP_Node 직접 상속)

```cpp
#include <UT/UT_DSOVersion.h>
#include <SOP/SOP_Node.h>
#include <OP/OP_Operator.h>
#include <OP/OP_OperatorTable.h>
#include <PRM/PRM_Include.h>

class SOP_MyNode : public SOP_Node {
public:
    static OP_Node *myConstructor(OP_Network *net, const char *name, OP_Operator *op);
    static PRM_Template myTemplateList[];
protected:
    SOP_MyNode(OP_Network *net, const char *name, OP_Operator *op)
        : SOP_Node(net, name, op) {
        mySopFlags.setManagesDataIDs(true); // 수동 Data ID 관리
    }
    OP_ERROR cookMySop(OP_Context &context) override;
};

void newSopOperator(OP_OperatorTable *table) {
    table->addOperator(new OP_Operator(
        "hdk_mynode", "My Node", SOP_MyNode::myConstructor,
        SOP_MyNode::myTemplateList, 0, 1, 0, OP_FLAG_GENERATOR));
}
```

### 최신 패턴 (SOP_NodeVerb 기반)

```cpp
#include "SOP_MyNode.proto.h"  // 자동생성 파라미터 클래스
#include <SOP/SOP_NodeVerb.h>

class SOP_MyNodeVerb : public SOP_NodeVerb {
public:
    SOP_NodeParms *allocParms() const override { return new SOP_MyNodeParms(); }
    SOP_NodeCache *allocCache() const override { return new SOP_NodeCache(); }
    UT_StringHolder name() const override { return theSOPTypeName; }
    CookMode cookMode(const SOP_NodeParms*) const override { return COOK_GENERIC; }
    void cook(const CookParms &cookparms) const override;
    static const SOP_NodeVerb::Register<SOP_MyNodeVerb> theVerb; // 자동 등록
};

// 파라미터: raw string literal DSFile
const char *const theDsFile = R"THEDSFILE(
{
    name parameters
    parm { name "radius" label "Radius" type float default { 1.0 } }
}
)THEDSFILE";
```

### SOP_Node 브릿지 클래스 (NodeVerb 필수!)

Houdini 21.0에서 `SOP_Node::cookMySop()`은 **pure virtual** (`= 0`)이다.
`cookVerb()`를 override해도 `cookMySop()` 구현이 없으면 abstract class → 인스턴스화 불가.

**해결:** `cookMyselfAsVerb()` 헬퍼를 사용하여 `cookMySop()`을 Verb로 브릿지한다.

```
SOP_Node (Houdini 21.0 헤더)
├─ cookMySop(OP_Context&) = 0        ← pure virtual (반드시 구현)
├─ cookVerb() { return nullptr; }    ← virtual, 기본값 null
└─ cookMyselfAsVerb(OP_Context&)     ← 헬퍼: cookVerb()→Verb→cook() 파이프라인 실행
```

**주의:** Houdini 21.0의 `OP_Operator` 생성자는 `buildTemplates` 함수 포인터를 받지 **않는다**.
4번째 인자로 `PRM_Template*` 또는 `OP_TemplatePair*`만 받는다.
`PRM_TemplateBuilder`로 `PRM_Template*`를 만들어 직접 전달해야 한다.

```cpp
#include <PRM/PRM_TemplateBuilder.h>  // 필수!

// theDsFile → PRM_Template* 변환 (static으로 한 번만 생성)
static PRM_Template* getTemplates() {
    static PRM_TemplateBuilder templ("SOP_MyNode.cpp", theDsFile);
    return templ.templates();
}

// SOP_Node 상속 클래스 (Verb 사용 시)
class SOP_MyNode : public SOP_Node {
public:
    static OP_Node *myConstructor(OP_Network*, const char*, OP_Operator*);
    const SOP_NodeVerb *cookVerb() const override;
protected:
    SOP_MyNode(OP_Network *net, const char *name, OP_Operator *op)
        : SOP_Node(net, name, op) {
        mySopFlags.setManagesDataIDs(true);
    }
    // ★ 필수: pure virtual 구현 → cookMyselfAsVerb()로 위임
    OP_ERROR cookMySop(OP_Context &context) override {
        return cookMyselfAsVerb(context);
    }
};

const SOP_NodeVerb *SOP_MyNode::cookVerb() const {
    return SOP_NodeVerb::lookupVerb("hdk_mynode");
}

// newSopOperator: PRM_Template* 직접 전달 (Houdini 21.0 호환)
void newSopOperator(OP_OperatorTable *table) {
    OP_Operator *op = new OP_Operator(
        "hdk_mynode", "My Node",
        SOP_MyNode::myConstructor,
        getTemplates(),  // ★ PRM_Template* 직접 전달
        0, 1, nullptr, OP_FLAG_GENERATOR);
    op->setOpTabSubMenuPath("HDK");
    table->addOperator(op);
}
```

### Verb의 gdp 접근 (cookMySop과 다름)

```cpp
void SOP_MyNodeVerb::cook(const CookParms &cookparms) const {
    // Verb에서는 this->gdp가 없다. CookParms를 통해 접근:
    GU_Detail *gdp = cookparms.gdh().gdpNC();   // 쓰기용
    // const GU_Detail *input = cookparms.inputGeo(0);  // 읽기 전용 입력

    // 파라미터 접근: .proto.h가 생성한 타입-세이프 getter
    const auto &parms = cookparms.parms<SOP_MyNodeParms>();
    fpreal radius = parms.getRadius();

    // Generator: clearAndDestroy() → 새로 생성
    // Filter:   COOK_INPLACE 또는 COOK_DUPLICATE 사용
}
```

### SOP 쿠킹 필수 패턴

```cpp
OP_ERROR SOP_MyNode::cookMySop(OP_Context &context) {
    // 입력 잠금 (RAII, 필수!)
    OP_AutoLockInputs inputs(this);
    if (inputs.lock(context) >= UT_ERROR_ABORT) return error();

    // 시간 의존 SOP
    OP_Node::flags().setTimeDep(true);

    // Data ID: 변경된 어트리뷰트만 bump
    gdp->getP()->bumpDataId();

    // 지오메트리 복사 전략 (여러 소스 합칠 때)
    // GEO_COPY_ONCE (1개), GEO_COPY_START/ADD/END (여러개)
    gdp->copy(*src, GEO_COPY_ONCE, true, false, GA_DATA_ID_CLONE);

    // 새 요소 추적
    GA_IndexMap::Marker pointmarker(gdp->getPointMap());
    gdp->copy(*src, GEO_COPY_ADD, ...);
    gdp->transform(xform, primmarker.getRange(), pointmarker.getRange(), false);

    return error();
}
```

### Data ID Bump 패턴 (Houdini 21.0)

`setManagesDataIDs(true)` 선언 시, 변경한 항목의 Data ID를 수동으로 bump해야 한다.
안 하면 뷰포트가 변경을 감지 못한다.

**주의:** `GA_Topology`에는 `bumpDataId()`가 **없다** (`getDataId()`만 있음).
토폴로지 변경은 `GA_Detail`의 헬퍼 메서드로 bump해야 한다.

```cpp
// 개별 bump (변경한 것만)
gdp->getP()->bumpDataId();              // GA_Attribute — P 변경 시
gdp->getPrimitiveList().bumpDataId();   // GA_PrimitiveList — 프리미티브 추가/삭제 시

// 토폴로지 관련 bump (GA_Detail 메서드)
gdp->bumpDataIdsForAddOrRemove(
    true,   // points 추가/삭제됨?
    true,   // vertices 추가/삭제됨?
    true);  // primitives 추가/삭제됨?
gdp->bumpDataIdsForRewire();            // 버텍스→포인트 재연결만 한 경우

// 전부 bump (Generator에서 clearAndDestroy 후 새로 생성한 경우)
gdp->bumpAllDataIds();
```

| 상황 | 사용할 메서드 |
|------|-------------|
| Generator (전부 새로 생성) | `bumpAllDataIds()` |
| Filter (P만 수정) | `gdp->getP()->bumpDataId()` |
| Filter (프리미티브 추가/삭제) | `bumpDataIdsForAddOrRemove(false,true,true)` |
| Filter (버텍스 재연결) | `bumpDataIdsForRewire()` |

### MULTIPARM 패턴 (SOP_HDKObject)

```cpp
static PRM_Template theObjectTemplates[] = {
    PRM_Template(PRM_TOGGLE, 1, &objnames[3], PRMoneDefaults),
    PRM_Template(PRM_STRING, PRM_TYPE_DYNAMIC_PATH, 1, &objnames[1], 0, 0, 0, 0, &PRM_SpareData::sopPath),
    PRM_Template()
};
PRM_Template myTemplateList[] = {
    PRM_Template(PRM_MULTITYPE_LIST, theObjectTemplates, 2, &objnames[0], PRMoneDefaults),
    PRM_Template()
};

// 인스턴스 접근
int NUMOBJ() { return evalInt("numobj", 0, 0.0f); }
void SOPPATH(UT_String &str, int i, fpreal t) {
    evalStringInst("objpath#", &i, str, 0, t);
}
```

---

## PRM_Template Parameter Definition

```cpp
static PRM_Name names[] = {
    PRM_Name("radius", "Radius"),
    PRM_Name("center", "Center"),
};
static PRM_Default radiusDefault(1.0);

PRM_Template myTemplateList[] = {
    PRM_Template(PRM_FLT_J, 1, &names[0], &radiusDefault),  // float
    PRM_Template(PRM_XYZ_J, 3, &names[1], PRMzeroDefaults), // vector3
    PRM_Template(PRM_STRING, 1, &theName),                    // string
    PRM_Template(PRM_TOGGLE, 1, &theName, PRMoneDefaults),   // toggle
    PRM_Template(PRM_INT_J, 1, &theName, PRMoneDefaults),    // int
    PRM_Template(PRM_ORD, 1, &theName, PRMzeroDefaults, &choiceList), // menu
    PRM_Template()  // 종료자 (필수!)
};
```

---

## GA_Handle Attribute Access

```cpp
// 읽기 전용
GA_ROHandleV3 Phandle(gdp->findFloatTuple(GA_ATTRIB_POINT, "P", 3));
if (Phandle.isValid()) { UT_Vector3 pos = Phandle.get(ptoff); }

// 읽기/쓰기
GA_RWHandleF life(gdp->addFloatTuple(GA_ATTRIB_POINT, "life", 1));
life.set(ptoff, 1.0f);

// 문자열
GA_ROHandleS name(gdp->findStringTuple(GA_ATTRIB_PRIMITIVE, "name", 1));

// 벡터 타입 설정
GA_RWAttributeRef velref = gdp->addFloatTuple(GA_ATTRIB_POINT, "v", 3);
velref.setTypeInfo(GA_TYPE_VECTOR); // 트랜스폼 시 벡터로 변환
GA_RWHandleV3 velhandle(velref);
```

| Handle | Type | 예시 |
|--------|------|------|
| `GA_ROHandleF` / `GA_RWHandleF` | float | life, pscale |
| `GA_ROHandleV3` / `GA_RWHandleV3` | UT_Vector3 | P, N, Cd, v |
| `GA_ROHandleV2` / `GA_RWHandleV2` | UT_Vector2 | uv |
| `GA_ROHandleI` / `GA_RWHandleI` | int | id |
| `GA_ROHandleS` / `GA_RWHandleS` | string | name, shop_materialpath |

---

## DM — Viewport Render Hooks

### 아키텍처

```
DM_SceneHook (팩토리) → DM_SceneRenderHook (렌더러)
```

### Hook 타이밍

| Hook Type | 용도 |
|-----------|------|
| `DM_HOOK_BACKGROUND` | 배경 교체 |
| `DM_HOOK_BEAUTY` | 메인 렌더 패스 (Before/After) |
| `DM_HOOK_UNLIT` | 비조명 패스 |
| `DM_HOOK_FOREGROUND` | HUD/오버레이 |
| `DM_HOOK_POST_RENDER` | 후처리 |

### Policy

| Policy | 의미 |
|--------|------|
| `DM_HOOK_REPLACE_NATIVE` | Houdini 기본 렌더링 교체 |
| `DM_HOOK_BEFORE_NATIVE` | 기본 렌더링 전 |
| `DM_HOOK_AFTER_NATIVE` | 기본 렌더링 후 |

### 등록 패턴

```cpp
void newRenderHook(DM_RenderTable *table) {
    table->registerSceneHook(new MyHook, DM_HOOK_BEAUTY, DM_HOOK_BEFORE_NATIVE);
    table->installSceneOption("my_option", "My Option Label");
}

bool MyRenderHook::render(RE_RenderContext r, const DM_SceneHookData &hook_data) {
    if (!hook_data.disp_options->isSceneOptionEnabled("my_option")) return false;
    // GL 코드
}
```

### RE API (렌더링)

```cpp
// 셰이더
RE_Shader *shader = RE_Shader::create("name");
shader->addShader(r, RE_SHADER_VERTEX, src, "vert", 0);
shader->addShader(r, RE_SHADER_FRAGMENT, src, "frag", 0);
shader->linkShaders(r);
r->pushShader(shader); ... r->popShader();

// 빌트인 셰이더
static RE_ShaderHandle theShader("material/GL32/beauty_lit.prog");
r->bindShader(theShader);

// 텍스처
RE_Texture *tex = RE_Texture::newTexture(RE_TEXTURE_2D);
tex->setResolution(w, h); tex->setFormat(RE_GPU_UINT8, 3);
tex->setTexture(r, data);

// FBO
RE_OGLFramebuffer *fbo = new RE_OGLFramebuffer();
fbo->setResolution(w, h);
RE_Texture *rt = fbo->createTexture(r, RE_GPU_FLOAT16, 4);
r->pushDrawFramebuffer(fbo); ... r->popDrawFramebuffer();

// 뷰티패스 접근
RE_Texture *beauty = viewport().getBeautyPassTexture(r);

// VBO
RE_Geometry *geo = new RE_Geometry(numpts);
geo->cacheBuffers(getCacheName());
RE_VertexArray *pos = geo->findCachedAttrib(r, "P", RE_GPU_FLOAT32, 3, RE_ARRAY_POINT, true);
if (pos->getCacheVersion() != version) {
    auto *data = static_cast<UT_Vector3F*>(pos->map(r));
    // write data
    pos->unmap(r);
    pos->setCacheVersion(version);
}
geo->connectAllPrims(r, 0, RE_PRIM_TRIANGLES, NULL, true);
geo->draw(r, 0);
```

---

## GUI — Primitive Render Hooks

### 등록 모드

```cpp
void newRenderHook(DM_RenderTable *dm_table) {
    // GEO 기반
    dm_table->registerGEOHook(new MyHook(), GA_PrimitiveTypeId(type), priority,
        GUI_HOOK_FLAG_NONE);         // 완전 대체
     // GUI_HOOK_FLAG_AUGMENT_PRIM   // 장식 추가

    // GT 기반 (리파인 필터)
    dm_table->registerGTHook(new MyHook(), GT_PRIM_POLYGON_MESH, priority,
        GUI_HOOK_FLAG_PRIM_FILTER);

    // 지오메트리 옵션
    dm_table->installGeometryOption("opt_id", "Label",
        GUI_GeometryOptionFlags(GUI_GEO_OPT_REFINE_ON_ACTIVATION));
}
```

### GR_Primitive 렌더 모드

```cpp
switch(render_mode) {
    case GR_RENDER_BEAUTY:       // 셰이딩
    case GR_RENDER_MATERIAL:     // 머티리얼
    case GR_RENDER_CONSTANT:     // 단색
    case GR_RENDER_WIREFRAME:    // 와이어프레임
    case GR_RENDER_HIDDEN_LINE:  // 히든 라인
    case GR_RENDER_DEPTH:        // 뎁스만
    case GR_RENDER_DEPTH_CUBE:   // 큐브맵 섀도우
    case GR_RENDER_DEPTH_LINEAR: // 선형 뎁스
    case GR_RENDER_MATTE:        // 매트
    case GR_RENDER_XRAY:         // X-Ray
    case GR_RENDER_OBJECT_PICK:  // 피킹
}
```

### update() reason 비트

```
GR_GEO_CHANGED | GR_GEO_TOPOLOGY_CHANGED | GR_GEO_ATTRIB_LIST_CHANGED
GR_GEO_SELECTION_CHANGED | GR_DISPLAY_OPTIONS_CHANGED
GR_INSTANCE_PARMS_CHANGED | GR_LOD_CHANGED
GR_MATERIALS_CHANGED | GR_MATERIAL_ASSIGNMENT_CHANGED
```

---

## Custom Primitive Pipeline (tetprim)

### GEO 레이어 (GEO_Primitive 상속)

필수 오버라이드:
```cpp
bool  isDegenerate() const override;
bool  getBBox(UT_BoundingBox*) const override;
void  reverse() override;
UT_Vector3 computeNormal() const override;
void  copyPrimitive(const GEO_Primitive*) override;
GA_DereferenceStatus dereferencePoint(GA_Offset, bool) override;
int   detachPoints(GA_PointGroup&) override;
const GA_PrimitiveJSON* getJSON() const override;
```

등록:
```cpp
void registerMyself(GA_PrimitiveFactory *factory) {
    theDefinition = factory->registerDefinition("HDK_MyPrim", allocCallback, GA_FAMILY_NONE, "tag");
    registerIntrinsics(*theDefinition);
    // GT or GR 등록
}
extern "C" { void newGeometryPrim(GA_PrimitiveFactory *f) { MyPrim::registerMyself(f); } }
```

Intrinsic 어트리뷰트:
```cpp
GA_START_INTRINSIC_DEF(MyPrim, NUM_INTRINSICS)
    GA_INTRINSIC_I(MyPrim, IDX, "name", getterFunc)
    GA_INTRINSIC_S(MyPrim, IDX, "name", getterFunc)
GA_END_INTRINSIC_DEF(MyPrim, GEO_Primitive)
```

### GT 레이어 (GT_GEOPrimCollect)

```cpp
class MyCollect : public GT_GEOPrimCollect {
    MyCollect(const GA_PrimitiveTypeId &id) { bind(id); }
    GT_GEOPrimCollectData* beginCollecting(...) const override;
    GT_PrimitiveHandle collect(...) const override;         // 오프셋 누적
    GT_PrimitiveHandle endCollecting(...) const override;   // → GT_PrimPolygonMesh 변환
};

// endCollecting에서:
shared  = geometry->getPointAttributes(filter);
vertex  = geometry->getVertexAttributes(filter, &ga_vertices);
uniform = geometry->getPrimitiveAttributes(filter, &ga_faces);
detail  = geometry->getDetailAttributes(filter);
return new GT_PrimPolygonMesh(counts, ptnums, shared, vertex, uniform, detail);
```

### GR 레이어 (GR_Primitive)

```cpp
// Houdini 빌트인 셰이더
static RE_ShaderHandle theShader("material/GL32/beauty_lit.prog");
static RE_ShaderHandle theLineShader("basic/GL32/wire_color.prog");

// 머티리얼 + 라이팅 바인딩
dp.opts->getLightList()->glLights()->bindForShader(r, shader);
mat->updateShaderForMaterial(r, 0, true, RE_SHADER_TARGET_TRIANGLE, shader);

// 인스턴싱
if(dp.draw_instanced)
    myGeo->drawInstanceGroup(r, idx, dp.instance_group);
else
    myGeo->draw(r, idx);
```

### GT vs GR 선택 (tetra.C)

```cpp
#ifndef TETRA_GR_PRIMITIVE
#include "GT_PrimTetra.C"  // GT: Houdini가 자동 렌더 (간단)
#else
#include "GR_PrimTetra.C"  // GR: 직접 GL 제어 (장식, 피킹 가능)
#endif
```

---

## Packed Primitive (GU_PackedImpl)

```cpp
class GU_PackedSphere : public GU_PackedImpl {
    GU_PackedFactory *getFactory() const override;
    GU_PackedImpl *copy() const override;
    bool isValid() const override;
    bool getBounds(UT_BoundingBox &box) const override;
    bool save(UT_Options&, const GA_SaveMap&) const override;
    bool load(GU_PrimPacked*, const UT_Options&, const GA_LoadMap&) override;
    GU_ConstDetailHandle getPackedDetail(GU_PackedContext*) const override;
    bool unpack(GU_Detail&, const UT_Matrix4D*) const override;
};

// Factory + Intrinsic 등록
class MyFactory : public GU_PackedFactory {
    MyFactory() : GU_PackedFactory("PackedSphere", "Packed Sphere") {
        registerIntrinsic("lod", IntGetterCast(&MyPacked::intrinsicLod),
                                  IntSetterCast(&MyPacked::setLOD));
    }
};

// LOD별 공유 지오메트리 캐싱
static UT_Lock theLock;
static GU_ConstDetailHandle getSphere(int lod) {
    UT_AutoLock lock(theLock);
    if (!theCache[lod]) theCache[lod] = new CacheEntry(lod);
    return theCache[lod]->detail();
}

// DSO
void newGeometryPrim(GA_PrimitiveFactory *f) { GU_PackedSphere::install(f); }
```

---

## SIM Patterns

### SIM_Data 매크로

```cpp
// .h
DECLARE_STANDARD_GETCASTTOTYPE();
DECLARE_DATAFACTORY(MyClass, BaseClass, "Label", getDopDescription());

// .C
IMPLEMENT_DATAFACTORY(MyClass);

// 데이터 접근
SIM_ScalarField *f = SIM_DATA_GET(*obj, "density", SIM_ScalarField);
SIM_ScalarField *f = SIM_DATA_CREATE(*obj, "density", SIM_ScalarField, 0);
const MyData *d = SIM_DATA_CASTCONST(source, MyData);
```

### GAS SubSolver

```cpp
class SIM_MyGas : public GAS_SubSolver {
    GET_DATA_FUNC_S(GAS_NAME_FIELDDEST, FieldDst);
    GET_DATA_FUNC_V3("center", Center);
    GET_DATA_FUNC_I("count", Count);
protected:
    bool solveGasSubclass(SIM_Engine&, SIM_Object*, SIM_Time, SIM_Time) override;
};

void initializeSIM(void*) { IMPLEMENT_DATAFACTORY(SIM_MyGas); }
```

### Voxel Tile 순회 패턴

```cpp
UT_VoxelArrayIteratorF vit;
vit.setArray(dst->fieldNC());
vit.setCompressOnExit(true);
vit.setPartialRange(info.job(), info.numJobs()); // 멀티스레드

for (vit.rewind(); !vit.atEnd(); vit.advance()) {
    if (vit.isStartOfTile()) {
        if (boss->opInterrupt()) break;
        // 타일 상수 최적화
        if (vit.isTileConstant() && srcsampler.isTileConstant(vit, srcval)) {
            vit.getTile()->makeConstant(vit.getValue() + srcval);
            vit.skipToEndOfTile();
            continue;
        }
    }
    vit.setValue(vit.getValue() + srcsampler.getValue(vit));
}
```

---

## RAY — Mantra Procedurals

```cpp
class MyProc : public RAY_Procedural {
    int  initialize(const UT_BoundingBox*) override;  // 파라미터 import
    void getBoundingBox(UT_BoundingBox&) override;
    void render() override {
        RAY_ProceduralGeo geo = createGeometry();
        // build geometry...
        RAY_ProceduralChildPtr obj = createChild();
        obj->addGeometry(geo);
    }
};

class ProcDef : public RAY_ProceduralFactory::ProcDefinition {
    ProcDef() : ProcDefinition("myproc") {}
    RAY_Procedural *create() const override { return new MyProc(); }
    RAY_ProceduralArg *arguments() const override { return theArgs; }
};

void registerProcedural(RAY_ProceduralFactory *f) { f->insert(new ProcDef); }

// 모션 블러
geo.addVelocityBlur(preBlur, postBlur);           // 벨로시티 블러
auto g1 = geo.appendSegmentGeometry(shutter);      // 멀티세그먼트

// LOD 기반 분할
fpreal lod = getLevelOfDetail(box);
if (lod < threshold) fractalRender(); else fractalSplit();

// GT 레벨 렌더링
obj->addProcedural(new RAY_ProcGT(gt_prim));
```

---

## VEX Custom Functions

```cpp
void newVEXOp(void*) {
    // 시그니처: "함수명@리턴타입인자들"  &=output, F=float, I=int, +=variadic
    new VEX_VexOp("myfunc@&FI"_sh,
        eval32, eval64,              // VEX_32/64 evaluator
        VEX_ALL_CONTEXT,
        init32, init64,              // 공유 데이터 init (nullable)
        cleanup32, cleanup64,        // cleanup (nullable)
        VEX_OPTIMIZE_0);             // 0=no opt, 1=reduced

    // Variadic
    new VEX_VexOp("myprint@+"_sh, ...);
}

template<VEX_Precision PREC>
static void eval(int, void *argv[], void *data) {
    VEXfloat<PREC> *result = (VEXfloat<PREC>*)argv[0];
    const VEXint<PREC> *arg = (const VEXint<PREC>*)argv[1];
    *result = ...;
}
```

---

## COP2 Patterns

### Pixel Operation (COP2_PixelOp)

```cpp
class MyPixelFunc : public RU_PixelFunction {
    bool eachComponentDifferent() const override { return true; }
    static float op(RU_PixelFunction *pf, float val, int comp);
    RUPixelFunc getPixelFunction() const override { return op; }
};

RU_PixelFunction* MyOp::addPixelFunction(const TIL_Plane*, int, float t, ...) {
    return new MyPixelFunc(parms...);
}
void newCop2Operator(OP_OperatorTable *table) { ... }
```

### Generator (COP2_Generator)

```cpp
class MyGen : public COP2_Generator {
    TIL_Sequence* cookSequenceInfo(OP_ERROR&) override;
    COP2_ContextData* newContextData(const TIL_Plane*, ...) override;
    OP_ERROR generateTile(COP2_Context&, TIL_TileList*) override;
};

// 타일 생성 (멀티스레드!)
OP_ERROR generateTile(COP2_Context &ctx, TIL_TileList *tiles) {
    TIL_Tile *itr; int ti;
    FOR_EACH_UNCOOKED_TILE(tiles, itr, ti) {
        for(int i=0; i<tiles->mySize; i++) dest[i] = ...;
        writeFPtoTile(tiles, dest, ti);
    }
}
```

---

## CHOP Patterns

```cpp
class CHOP_MyNode : public CHOP_Realtime {
    OP_ERROR cookMyChop(OP_Context&) override;     // 전체 쿡
    OP_ERROR cookMySlice(OP_Context&, int start, int end) override; // 실시간
    int isSteady() const override;
    ut_RealtimeData* newRealtimeDataBlock(const char*, const CL_Track*, fpreal) override;
};

// 중간값 스태싱
class MyData : public ut_RealtimeData {
    fpreal myPrevValue;
    bool loadStates(UT_IStream&, int) override;
    bool saveStates(UT_OStream&) override;
};

void newChopOperator(OP_OperatorTable *table) { ... }
```

---

## Build System

### CMake (최신)

```cmake
cmake_minimum_required(VERSION 3.12)
project(SOP_Star)
find_package(Houdini REQUIRED)
houdini_generate_proto_headers(FILES SOP_Star.C)
houdini_add_library(SOP_Star SHARED SOP_Star.C)
target_link_libraries(SOP_Star Houdini)
houdini_configure_target(SOP_Star)
```

### hcustom (레거시)

```bash
hcustom SOP_Star.C
```

---

## Debugging

### 디버그 빌드 (Debug Info 활성화)

**hcustom:**
```bash
hcustom -g SOP_Flatten.C
```

**Makefile (Linux/Mac — g++):**
```makefile
OPTIMIZER = -g
include $(HFS)/toolkit/makefiles/Makefile.gnu
```

**Makefile (Windows — CL.exe):**
```makefile
OPTIMIZER = /Z7 /Od
include $(HFS)/toolkit/makefiles/Makefile.nmake
```

---

### GDB (Linux/Mac)

`$HFS/bin/houdini`는 wrapper 스크립트 → 실제 바이너리 `houdini-bin` 직접 지정.

```bash
gdb $HFS/bin/houdini-bin
(gdb) run -foreground          # ★ -foreground 필수 (fork 방지, 없으면 "Program exited normally")
# 크래시 발생 시:
(gdb) where                    # 또는 bt — 스택 트레이스 출력
(gdb) up / down                # 프레임 이동
(gdb) print <변수>             # 현재 프레임 변수 출력
(gdb) run -foreground          # 프로세스 전체 재시작 → 디스크의 최신 DSO를 새로 로드 (hot-reload 아님)
```

**브레이크포인트 설정:**
```bash
# gdb 시작 직후에는 shared lib 심볼 미로드 → Ctrl-C로 중단 후 설정
(gdb) break HDK_Sample::SOP_Flatten::cookMySop(OP_Context &)
(gdb) break SOP_Flatten.C:166
(gdb) continue
```

**스텝 명령:**

| 명령 | 단축 | 동작 |
|------|------|------|
| `where` / `bt` | `whe` | 스택 트레이스 |
| `run` | `r` | (재)시작 |
| `continue` | `c` | 계속 실행 |
| `next` | `n` | step over |
| `step` | `s` | step into |
| `print` | `p` | 변수 출력 |
| `quit` | `q` | 종료 |

> ENTER(빈 입력) → 이전 명령 반복 실행

**코어 파일로 사후 분석:**
```bash
gdb $HFS/bin/houdini-bin core
```

---

### DDD (Linux/Mac GUI 디버거)

gdb 백엔드 사용. `http://www.gnu.org/software/ddd/`

```bash
ddd $HFS/bin/houdini-bin
# Program -> Run, 인자: -foreground
# Status -> Backtrace      (스택 트레이스)
# Source -> Breakpoints    (브레이크포인트)
# Program -> Interrupt     (Ctrl-C 대체)
# gdb 명령은 DDD 내 gdb 창에서 직접 실행 가능
```

---

### Valgrind (Linux/Mac 메모리 검사)

Houdini는 기본적으로 jemalloc 사용 → native libc 교체 필수.

```bash
LD_PRELOAD=/lib/libc.so.6 valgrind houdini -foreground
```

> 시작 시 비디오 드라이버 관련 false positive 발생 — 무시.
> 실행 속도 10~50x 저하 정상.
> 초기화되지 않은 메모리 접근, 메모리 누수 등 자동 탐지.

---

### Visual Studio (Windows)

크래시 시 JIT 디버거 자동 팝업 → Yes 클릭으로 Visual Studio 연결.
디버그 빌드(`/Z7 /Od`) 시 소스 코드와 라인 번호 표시.

| 단축키 | 동작 |
|--------|------|
| `F10` | step over |
| `F11` | step into |
| `F5` | continue |
| `Shift+F5` | 디버깅 종료 |

Call Stack 패널 → 스택 트레이스  
Watch List 패널 → 변수 값 확인

---

### UT_ASSERT

```cpp
#include <UT/UT_Assert.h>

UT_ASSERT(expression);  // false면 팝업: Debug / Ignore / Always Ignore
```

- 디버그 빌드(`-g` / `/Z7`)에서만 활성화 → **릴리스 빌드에서 성능 오버헤드 없음**
- Windows: Debug 클릭 시 Visual Studio 자동 연결
- Linux/Mac: `abort()` → gdb 실행 중이면 중단, 아니면 core 파일 생성

**Linux xmessage 텍스트 미표시 우회:**
```bash
export HOUDINI_ASSERT_COMMAND="gmsgp -b Debug:1,Ignore:2,IgnoreAll:3 --title=\"Assertion Failure\" -print"
```

---

### Crash Recovery 비활성화

Houdini는 크래시 시 hip 자동 저장 후 종료 → 디버거 사용 시 방해됨.

```bash
# 디버깅 시: 크래시 복구 비활성화 (Unix는 core 파일 생성, gdb 실행 중이면 core 없음)
export HOUDINI_COREDUMP=1
export HOUDINI_UI_COREDUMP=1

# 복원하려면:
unset HOUDINI_UI_COREDUMP
```

Windows: `HOUDINI_COREDUMP` 설정 시 Just-In-Time 디버깅 활성화.

---

### Plugin 로드 실패 진단 (HOUDINI_DSO_ERROR)

플러그인이 Houdini에 로드되지 않을 때 (외부 라이브러리 누락, 심볼 없음 등):

```bash
export HOUDINI_DSO_ERROR=1
houdini  # 로드 실패한 .so/.dll에 대한 에러 메시지 출력
```

원인: 플러그인이 참조하는 외부 라이브러리가 없거나, 심볼이 resolve되지 않은 경우.

---

### Hot-Reload (재시작 없이 코드 반영)

**결론: compiled HDK DSO의 in-process hot-reload는 불가능하다.**

OS 동적 링커는 이미 메모리에 매핑된 shared library의 언로드/재로드를 허용하지 않는다.
Houdini도 이를 우회하는 메커니즘을 제공하지 않는다.

| 방법 | 결과 |
|------|------|
| `opunload` hscript | ❌ 지오메트리 캐시 플러시 전용, DSO와 무관 |
| `otrefresh` hscript | ❌ HDA/OTL 전용, C++ DSO 미지원 |
| Visual Studio Edit & Continue (`/ZI`) | ❌ HDK DLL에서 신뢰성 없음, 공식 빌드 플래그는 `/Z7` |
| `(gdb) run -foreground` | ✅ 전체 프로세스 재시작 → 최신 DSO 반영 (hot-reload 아님) |

**표준 반복 워크플로우:**
```
코드 수정 → 재컴파일 (CMake/hcustom) → (gdb) run -foreground 또는 Houdini 재시작
```

**제한적 우회법 (리스키):** 새 파일명으로 빌드하고 Python API로 런타임 추가 로드.
노드 타입명도 변경해야 하며 세션 불안정 위험 있음 → 실무 비권장.
```python
# 새 DSO를 완전히 다른 이름으로 빌드한 경우에만 사용 가능
hou.sopNodeTypeCategory().loadDSO("/path/to/SOP_MyNode_v2.so")
```

---

## Core Class Reference

### Rendering (RE)

| 클래스 | 역할 |
|--------|------|
| `RE_Render` | GL 상태 머신 래퍼 |
| `RE_Shader` | GLSL 셰이더 |
| `RE_ShaderHandle` | 빌트인 .prog 참조 |
| `RE_Texture` | GL 텍스처 |
| `RE_Geometry` | VBO/VAO 래퍼 |
| `RE_VertexArray` | 버텍스 버퍼 + 캐시 |
| `RE_OGLFramebuffer` | FBO |
| `RE_OcclusionQuery` | GL Query |

### Viewport (DM/GUI)

| 클래스 | 역할 |
|--------|------|
| `DM_SceneHook` | 렌더훅 팩토리 |
| `DM_SceneRenderHook` | GL 드로잉 |
| `DM_VPortAgent` | 뷰포트 접근 |
| `GUI_PrimitiveHook` | 프리미티브 훅 팩토리 |
| `GR_Primitive` | 커스텀 프리미티브 GL |

### Geometry (GA/GEO/GU/GT)

| 레이어 | 역할 |
|--------|------|
| `GA_*` | Attribute 레이어 |
| `GEO_*` | Primitive 정의 |
| `GU_*` | Utility 알고리즘 |
| `GT_*` | Geometry Transport |

### Simulation (SIM)

| 클래스 | 역할 |
|--------|------|
| `SIM_Data` | 데이터 기본 클래스 |
| `SIM_Solver` / `SIM_SingleSolver` | 솔버 |
| `GAS_SubSolver` | 서브솔버 |
| `SIM_Force` | 포스 |
| `SIM_ScalarField` / `SIM_VectorField` | 필드 |

---

## Vector Type Deprecation (Houdini 21.0)

`UT_Vector3`는 deprecated. `UT_VectorTypes.h`에 정의:

| 타입 | 기반 | 용도 |
|------|------|------|
| `UT_Vector3F` | fpreal32 (float) | P 등 float 정밀도 충분한 경우 |
| `UT_Vector3D` | fpreal64 (double) | 시뮬레이션 등 높은 정밀도 |
| `UT_Vector3R` | fpreal (빌드 따라 다름) | 일반적으로 가장 안전 |
| `UT_Vector3` | float (하드코딩) | **deprecated** |

주의: `GA_Detail::setPos3()`등 HDK API가 아직 `UT_Vector3`을 사용. `UT_Vector3F`와 동일한 fpreal32 기반이므로 호환.

Narrowing conversion: `UT_Vector3R`은 fpreal(double) 기반이므로 `{}` 초기화 시 narrowing 에러 발생 가능 → `()` 초기화 사용 또는 명시적 캐스트.

---

## DS File Format Rules

### 중괄호 공백 규칙 (★ 중요)

`PRM_TemplateBuilder`의 런타임 파서는 `generate_proto.py`보다 엄격하다.

```
✗ 파싱 실패 (공백 없음):
default {"5"}
range {3! 64}

✓ 정상:
default { "5" }
range { 3! 64 }
```

`proto.h` 생성(빌드 시)은 성공하지만 런타임에서 파라미터 등록 실패 → "Invalid parameter name" 에러. 빌드 에러가 아닌 **런타임 에러**로 나타나므로 디버깅이 어려움.

---

## VERB_NAME Constant Pattern

Verb 등록 이름이 3곳에서 사용되므로, 상수 하나로 통일하여 오타를 구조적으로 방지:

```cpp
static constexpr const char* const VERB_NAME = "hdk_mynode";

// 1. Verb 등록
UT_StringHolder name() const override { return VERB_NAME; }

// 2. Verb 검색
const SOP_NodeVerb* SOP_MyNode::cookVerb() const {
    return SOP_NodeVerb::lookupVerb(VERB_NAME);
}

// 3. 노드 타입 등록
OP_Operator* op = new OP_Operator(VERB_NAME, "My Node", ...);
```

### Verb 자동 등록 (C++17 inline static)

Houdini 21.0은 C++17 (`/std:c++17`). `inline static`으로 선언+정의를 한 줄로:

```cpp
// C++17: 클래스 안에서 선언 + 정의 완료 (클래스 밖 정의 불필요)
static inline const SOP_NodeVerb::Register<SOP_MyNodeVerb> the_verb{};

// 전통 방식: 선언/정의 분리
// 헤더:
static const SOP_NodeVerb::Register<SOP_MyNodeVerb> the_verb;
// .cpp:
const SOP_NodeVerb::Register<SOP_MyNodeVerb> SOP_MyNodeVerb::the_verb;
```

---

## KD-Tree / Point Cloud Pattern

VEX `pcopen/pciterate/pcimport`의 HDK 대응. `GEO_PointTree.h` 사용.

### 구축 + 검색

```cpp
#include <GEO/GEO_PointTree.h>
#include <UT/UT_KDTree.h>           // ut_KDPQueuePtr, UT_KDTree::createQueue()

GEO_PointTreeGAOffset tree;
tree.build(search_gdp, nullptr);    // 데이터 수집 (nullptr = 전체 포인트)
tree.buildIfNeeded();                // 밸런싱 완료 (검색 전 필수)

// 검색 결과 배열
GEO_PointTreeGAOffset::IdxArrayType neighbors;  // = UT_Array<GA_Offset>
UT_FloatArray distances;

// 방법 1: 기본 (매 호출마다 내부 queue 생성/소멸)
int found = tree.findNearestGroupIdx(pos, radius, max_pts, neighbors, distances);

// 방법 2: queue 재사용 (★ 루프에서 반복 검색 시 이것 사용)
ut_KDPQueuePtr queue = UT_KDTree::createQueue();  // 팩토리 메서드 (직접 생성 불가)
int found = tree.findNearestGroupIdxQueue(pos, radius, max_pts, neighbors, distances, *queue);
```

### VEX → HDK 대응표

| VEX | HDK |
|-----|-----|
| `pcopen(1,"P",@P,rad,npts)` | `tree.findNearestGroupIdx(pos, rad, npts, ...)` |
| `pciterate(handle)` + `pcimport` | `for (i < found) neighbors(i)` |
| `point(1,"P",pt)` | `ro_P.get(nb_off)` |
| `pcclose(handle)` | 스코프 벗어나면 자동 소멸 |

### ut_KDPQueue 주의사항

`ut_KDPQueue`는 `UT_KDTree.h`에 **forward declaration만** 있고 클래스 정의가 숨겨져 있다.
직접 `ut_KDPQueue queue;` 생성 불가 → `UT_KDTree::createQueue()` 팩토리 사용 필수.
반환 타입 `ut_KDPQueuePtr` = `UT_UniquePtr<ut_KDPQueue, ut_KDPQueueDeleter>`.

### 스레드 안전성

- `build()` / `buildIfNeeded()`: 쓰기 → 싱글스레드에서 미리 완료
- `findNearestGroupIdx*()`: 읽기 전용 → 스레드 안전
- `neighbors` / `distances`: 스레드 로컬로 선언해야 함

---

## Multithreading Pattern

### UTparallelForLightItems + GA_SplittableRange

```cpp
#include <GA/GA_SplittableRange.h>
#include <UT/UT_ParallelUtil.h>

UTparallelForLightItems(
    GA_SplittableRange(gdp->getPointRange()),
    [&](const GA_SplittableRange& range)
{
    // ★ 스레드 로컬 변수는 반드시 람다 안에서 선언
    UT_Array<GA_Offset> local_array;

    for (GA_Iterator it(range); !it.atEnd(); ++it)
    {
        const GA_Offset ptoff = *it;
        // 각 스레드가 서로 다른 ptoff에 쓰기 → 안전
        rw_P.set(ptoff, ...);
    }
});
```

### 함수 선택 기준

| 함수 | 용도 |
|------|------|
| `UTparallelForLightItems` | 포인트별 가벼운 작업 (세밀한 로드밸런싱) |
| `UTparallelFor` | 범용 |
| `UTparallelForHeavyItems` | 작업 단위가 무거울 때 (청크 크게) |

### 스레드 안전성 체크리스트

- GA_Handle get/set: 서로 다른 GA_Offset이면 안전
- KD-Tree 검색: buildIfNeeded() 완료 후 안전
- neighbors/distances: 반드시 람다 내 지역 변수
- isValid() 캐싱: 루프 밖에서 `const bool has_X = handle.isValid();`

---

## Node Color / Shape

생성자에서 설정. `setColorDefault(false)` 없이 `setColor()`만 호출하면 무시됨.

```cpp
#include <UT/UT_Color.h>

SOP_MyNode(...) : SOP_Node(...) {
    setColor(UT_Color(UT_RGB, 1.0f, 0.27f, 0.0f));  // #FF4500
    setColorDefault(false);  // ★ 필수: false여야 setColor 값 사용
    setNodeShape("diamond"); // bone, bulge, burst, camera, chevron_down/up,
                             // cigar, circle, cloud, diamond, ensign, gurgle,
                             // light, null, oval, peanut, pointy, rect, slash,
                             // squared, star, tabbed_left/right, task, tilted,
                             // trapezoid_down/up, wave 등
}
```

---

## CUDA + HDK Build Pattern

CUDA(.cu)는 nvcc로, HDK(.cpp)는 MSVC로 컴파일해야 하므로 분리 빌드.

### 프로젝트 구조

```
SOP_CUDANode/
├── CMakeLists.txt         ← project(...  CXX CUDA)
├── cuda/
│   ├── kernel.h           ← CPU 측 인터페이스 (CUDA 키워드 없음)
│   └── kernel.cu          ← GPU 커널 + 래퍼 (nvcc 컴파일)
├── src/
│   └── SOP_CUDANode.cpp   ← HDK Verb + Pack/Unpack (MSVC 컴파일)
└── include/
    └── SOP_CUDANode.h
```

### CMake 빌드 구조

```cmake
project(SOP_CUDANode CXX CUDA)
set(CMAKE_CUDA_ARCHITECTURES 89)  # RTX 40xx = sm_89

# 1) CUDA 커널 — static lib (nvcc)
add_library(cuda_kernel STATIC cuda/kernel.cu)

# 2) HDK DSO — shared lib (MSVC) + CUDA static lib 링크
add_library(${PROJECT_NAME} SHARED src/SOP_CUDANode.cpp ...)
target_link_libraries(${PROJECT_NAME} PRIVATE Houdini cuda_kernel)
houdini_configure_target(${PROJECT_NAME})
```

### 데이터 흐름 (CPU ↔ GPU)

```
GA_Handle → float[] → cudaMemcpy H→D → kernel<<<>>> → cudaMemcpy D→H → float[] → GA_Handle
  (pack)    (upload)                     (compute)       (download)       (unpack)
```

### kernel.h 작성 규칙

CPU 측(.cpp)에서 include하므로, `__global__`, `__device__` 등 CUDA 키워드를 포함하면 안 됨.
순수 C++ 함수 선언만 노출:

```cpp
// kernel.h — CUDA 키워드 없음
bool cudaMyKernel(float* data, int count, float param);

// kernel.cu — CUDA 키워드 사용
__global__ void my_kernel(float* data, int count, float param) { ... }
bool cudaMyKernel(float* data, int count, float param) {
    cudaMalloc(...); cudaMemcpy(...); my_kernel<<<>>>(...); cudaMemcpy(...); cudaFree(...);
}
```
