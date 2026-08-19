# Chapter 32: An Introduction to Shader Interfaces
> 저자: Matt Pharr (NVIDIA)

## 핵심 개념
- **해결하려는 문제**: 런타임에 셰이더를 모듈별로 조합하여 유연한 셰이딩 시스템 구축
- Cg 1.2의 **셰이더 인터페이스** 기능 — Java/C#의 인터페이스, C++의 추상 클래스와 유사
- 셰이더 순열(permutation) 폭발 문제를 인터페이스 기반 조합으로 해결
- 런타임에 구체적 구현체를 바인딩하면 Cg 런타임이 최종 셰이더 코드를 자동 생성
- #ifdef 전처리기 기반 조합의 한계를 극복

## 기술적 세부사항

### 문제: 셰이더 순열 폭발
- 라이트 타입 N종 × 머티리얼 M종 × 기타 옵션 = 조합 폭발
- #ifdef로 관리하면 코드가 복잡해지고 확장이 어려움
- if 분기로 런타임 선택하면 불필요한 GPU 사이클 낭비

### 해결: 인터페이스 기반 조합

#### Light 인터페이스 정의
```cg
interface Light {
    float3 illuminate(float3 P, out float3 L);
};
```

#### 구체적 라이트 구현
```cg
struct SpotLight : Light {
    sampler2D shadow;
    samplerCUBE distribution;
    float3 Plight, Clight;
    float3 illuminate(float3 P, out float3 L) {
        L = normalize(Plight - P);
        return Clight * tex2D(shadow, P).xxx 
                       * texCUBE(distribution, L).xyz;
    }
};
```

#### 프래그먼트 프로그램에서 사용
```cg
void main(Light lights[],  // unsized array — 런타임에 크기 결정
          ...) {
    for (int i = 0; i < lights.length; i++) {
        float3 L;
        float3 Cl = lights[i].illuminate(P, L);
        color += Cl * max(dot(N, L), 0);
    }
}
```

### Cg 런타임 바인딩 과정
1. 프래그먼트 프로그램을 인터페이스 타입으로 컴파일
2. 런타임에 `cgConnectParameter()`로 구체적 구현체 바인딩
3. Cg 런타임이 인터페이스 호출을 인라인 확장하여 최종 셰이더 생성
4. 최종 코드는 정적 셰이더와 동일한 효율

### 장점
- 런타임 오버헤드 없음 — 최종 컴파일된 코드는 하드코딩과 동일
- 모듈러 셰이더 라이브러리 구축 가능
- 새 라이트 타입 추가 시 기존 코드 수정 불필요

## 수식 및 알고리즘
```
// 인터페이스 기반 셰이더 조합 흐름
1. interface Light, Material, BumpMap 등 정의
2. 각 인터페이스의 구현체들 작성 (PointLight, SpotLight, ...)
3. 런타임에 씬 상태에 따라 구현체 선택
4. cgConnectParameter()로 바인딩
5. Cg 런타임이 인라인 확장 → 최종 GPU 코드 생성
6. 성능 손실 없이 유연한 조합 달성
```

## UE5 관점에서의 활용
- 이 개념은 UE5의 **Shader Permutation 시스템**으로 진화 — 컴파일타임에 #define 조합으로 셰이더 변형 생성
- UE5의 **Material Layer** 시스템도 인터페이스 기반 조합과 유사한 패턴
- HLSL은 Cg의 interface 키워드를 직접 지원하지 않지만, **Dynamic Branching** + **Uber Shader** 패턴으로 유사 효과
- UE5의 **Virtual Shader Source** 시스템이 #include와 매크로로 모듈러 셰이더 조합 구현
- 현대적 대안: **Bindless Resources** + **Material ID 기반 분기**로 순열 문제 완화

## 핵심 요약 (3줄)
1. Cg 셰이더 인터페이스는 OOP의 추상 클래스 개념을 셰이더에 도입하여, 런타임 조합 시 성능 손실 없이 유연성을 제공한다.
2. 핵심은 인라인 확장 — 런타임에 바인딩하더라도 최종 GPU 코드는 정적 셰이더와 동일한 효율이다.
3. 현대 엔진에서는 Shader Permutation, Material Layer, Uber Shader 등으로 같은 문제를 해결한다.
