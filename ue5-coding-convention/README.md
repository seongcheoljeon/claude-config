# ue5-coding-convention

UE5 C++ 코딩 컨벤션 Claude Code 플러그인.

## 다루는 영역

- 클래스 명명 (프로젝트 prefix, `UXx`, `AXx`, `FXx`, `EXx`, `SXx`)
- 멤버 변수/private 함수 (`_` prefix)
- 어설션 (`check`/`checkf`/`ensure`/`ensureMsgf`/`verify`)
- 타입 선언 (`int32`/`uint8` 사용, `int`/`long` 금지)
- 코드 포맷 (브레이스 줄 맞춤, switch 형식)
- enum 패턴 (`enum class : int32` + `Count` 멤버 + `static_assert`)
- RPC 명명 (`SERVER_`/`CLIENT_`/`NETMULTICAST_`)
- 데이터 검증 (`IsDataValid` 모든 검사 수행)

## 자동 트리거

다음 키워드를 포함한 질문에 자동 활성화:
- "UE5 C++ 작성/리뷰", "UE5 클래스 네이밍"
- "check 매크로", "UPROPERTY/UFUNCTION 명명"
- "RPC SERVER_/CLIENT_"

## 명시적 호출

```text
/ue5-coding-convention
```

## 함께 사용하면 좋은 plugin

- `ue5-rdg` — RDG 렌더 패스 작성 시 코딩 규칙 적용
- `unreal-dev-kb` — UE5 일반 작업 시 디버깅 cvar 함께
