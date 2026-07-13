---
name: Code Quality Principles
description: 안정성 최우선, SOLID 준수, 기초 지식 중시
type: feedback
originSessionId: 5f4e16a0-230b-4550-81ef-3397596f4cf4
---
**규칙**
1. **코드의 안정성(stability)이 최우선 가치**. 성능·간결함보다 안정성 우선.
2. **S.O.L.I.D 원칙 준수** (SRP, OCP, LSP, ISP, DIP).
3. **기초 지식(fundamentals)을 중요하게 다룸** — 언어 표준, 메모리 모델, GPU 파이프라인 등 저수준 원리를 얼버무리지 말 것.

**Why:** 그래픽스/엔진 코드는 한 번 불안정해지면 재현·디버깅이 매우 어려움. 또한 기초가 탄탄해야 UE·DX·Vulkan 문제를 근본 해결할 수 있음.

**How to apply:**
- 코드 제안 시 undefined behavior, race condition, lifetime 이슈, GPU-CPU 동기화 이슈를 선제적으로 점검.
- 설계 제안 시 SOLID 관점에서 책임 분리/의존성 방향을 검토.
- "이렇게 하면 됩니다" 대신 "왜 그렇게 되는지" (표준/스펙/엔진 내부 동작) 함께 설명.
