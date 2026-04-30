---
name: ue5-coding-convention
description: Unreal Engine 5 C++ coding convention for any UE5 project. Use when writing, reviewing, or generating UE5 C++ code. Applies to class naming (project prefix), member variables (_ prefix), assertions (check/checkf/ensure), type declarations (int32/uint8), code formatting (braces, switch), enum patterns, RPC naming, and data validation. Triggers on any UE5 C++ code generation or review request.
---

# UE5 C++ Coding Convention

UE5 C++ 코드 작성 시 적용하는 코딩 컨벤션. 프로젝트에 무관하게 공용으로 사용.

## Naming Rules

### Function & Variable Names
- 함수명: PascalCase (예: `MyFunction`, `GetPlayerHealth`)
- 변수명: snake_case (예: `some_variable`, `player_count`)
- 변수 타입 접두어 사용 금지 (헝가리안 표기법 금지)

```cpp
// Correct
void CalculateDamage();
int32 damage_value = 0;

// Wrong
void calculateDamage();  // camelCase
int32 iDamageValue = 0;  // Hungarian notation
```

### Project Prefix (권장)
프로젝트 고유 접두사를 정의하여 모든 클래스/구조체/열거형에 사용을 권장.
접두사는 프로젝트별로 결정 (예: 2~3자 약어).

```cpp
// 예시: 접두사가 "Xx"인 경우
UCLASS()
class UXxGameInstance : public UGameInstance { };

UCLASS()
class AXxCharacter : public ACharacter { };

USTRUCT()
struct FXxItemInfo { };

UENUM()
enum class EXxItemType : uint8 { };

// Slate Widget
class SXxInventoryPanel : public SCompoundWidget { };

class XxItemObject { };
```

### Member Variables & Private/Protected Functions
앞에 `_` 사용:

```cpp
public:
    void Foo() {}
    int32 _exp;

protected:
    void _Foo1() {}

private:
    void _Foo2() {}
    int32 _level;
```

### Constants
대문자와 `_` 조합, `constexpr` 사용:

```cpp
#define FOO_NUMBER 1
constexpr int32 MAX_LEVEL = 100;

class UXxExample
{
    static const int32 MAX_MEMBER = 2;
};
```

### Inheritance Naming
상속 분류 시 `_` 구분:

```cpp
class XxSkill { };
class XxSkill_FlameThrower : public XxSkill { };
```

## Header Files

`CoreMinimal.h` 사용:

```cpp
#pragma once
#include "CoreMinimal.h"
```

## Type Declarations

허용되는 타입만 사용:

| Use | Avoid |
|-----|-------|
| `bool` | `BOOL` |
| `int8`, `int16`, `int32`, `int64` | `int`, `long`, `short` |
| `uint8`, `uint16`, `uint32`, `uint64` | `byte` |
| `float`, `double` | |
| `TCHAR` | |

## Assertions

UE5 내장 매크로 사용:

### check / checkf
조건이 반드시 참이어야 하는 경우. 실패 시 크래시:

```cpp
bool SampleClass::Open(const int32 data_value, SampleParam* param)
{
    checkf(data_value > 0, TEXT("data_value must be > 0, got %d"), data_value);
    check(param != nullptr);
}
```

### verify / verifyf
check와 동일하나 DO_CHECK=0 빌드에서도 표현식이 실행됨 (부수 효과 있는 코드):

```cpp
verify(ImportantFunction() == true);
```

### ensure / ensureMsgf
실패해도 크래시하지 않음. 에러 리포트 전송 + 실행 계속. 복구 가능한 경로에 사용:

```cpp
if (ensureMsgf(ptr != nullptr, TEXT("ptr was null, skipping")))
{
    ptr->DoWork();
}
```

### static_assert in Switch
enum switch의 default에서 enum 크기 검사:

```cpp
switch (data_type)
{
case EXxDataType::Item: break;
case EXxDataType::Character: break;
default:
    {
        static_assert(static_cast<int32>(EXxDataType::Count) == 5,
            "New type added, implement here.");
        checkf(false, TEXT("Invalid type[%s]"),
            *UEnum::GetValueAsString(data_type));
    }
    break;
}
```

## Code Style

### Braces
if문 항상 중괄호, 줄 맞춤:

```cpp
// Correct
if (a)
{
    return;
}

// Wrong - same line brace
if (a) {
}

// Wrong - no brace
if (a)
    return;
```

### Logical NOT Operator
if문에서 `!` 연산자 사용 금지 (`!=`는 허용):

```cpp
// Correct
if (ptr == nullptr)
if (flag == false)
if (value != 0)

// Wrong
if (!ptr)
if (!flag)
```

### No Redundant Parentheses
중복 괄호 금지:

```cpp
// Correct
if (a && b)
return value;

// Wrong
if ((a && b))
return (value);
```

### Function Declaration
매개변수 없는 함수는 `()` 사용, `(void)` 금지:

```cpp
// Correct
void Initialize();
int32 GetCount();

// Wrong
void Initialize(void);
int32 GetCount(void);
```

### Switch
case는 `{`와 같은 라인:

```cpp
switch (foo)
{
case EXxType::Foo: break;
case EXxType::Bar:
    DoSomething();
    break;
}
```

### Auto
지역 scope 한정, 포인터/참조 명시:

```cpp
void Foo()
{
    auto* ptr = GetPtr();
    auto& ref = GetRef();
}
// 함수 리턴값에 auto 사용 금지
```

### Long Lines
논리연산자/콤마를 앞에 붙이고 줄바꿈:

```cpp
if ((0 == foo) && (1 == bar)
    && (2 == ceci))
{
}

void Foo(int32 i, float a, double b
    , float c, double d);
```

## Class Structure

### Method Order
H/Cpp 순서 일치:

```cpp
// .h
class XxExample
{
public:
    void Foo();
    void Bar();
};

// .cpp
void XxExample::Foo() {}
void XxExample::Bar() {}
```

### Functional Grouping
기능별로 함수/변수 묶기:

```cpp
class XxExample
{
// Movement ///////////////
public:
    void Move();
private:
    void _UpdateMove();
    float _move_speed = 0.0f;
// Movement ///////////////

// Attack /////////////////
public:
    void Attack();
private:
    int32 _attack_value = 1;
// Attack /////////////////
};
```

### Header Initialization
H 파일에서 초기화:

```cpp
class XxFoo
{
    int32 _level = 0;
    Bar* _bar = nullptr;
};
```

### Forward Declaration
1-2개는 인라인, 많으면 상단에:

```cpp
// Inline (1-2)
class XxClass
{
    TObjectPtr<class XxFoo> _foo;
};

// Top (3+)
class XxFoo;
class XxHoo;
class XxToo;

class XxClass
{
    TObjectPtr<XxFoo> _foo;
    TObjectPtr<XxHoo> _hoo;
    TObjectPtr<XxToo> _too;
};
```

## Enum

`enum class` 사용, `E` 접두사, 내용에 접두어 없음:

```cpp
enum class EXxItemType : int32
{
    None = 0,
    Weapon,
    Armor,
    Count,
};
```

## Init/Clear Pattern

자기 자신 초기화:

```cpp
class XxFoo
{
public:
    bool Init();
    void Clear();
};
```

## RPC Naming

| Direction | Prefix | Example |
|-----------|--------|---------|
| Client → Server | `SERVER_` | `SERVER_Fire()` |
| Server → Client | `CLIENT_` | `CLIENT_Fire()` |
| Netmulticast | `NETMULTICAST_` | `NETMULTICAST_Movement()` |

## Data Validation

저장/패키징 시 에러 출력용 `IsDataValid` 구현:

```cpp
EDataValidationResult UXxExample::IsDataValid(FDataValidationContext& Context) const
{
    EDataValidationResult result = Super::IsDataValid(Context);

    if (_required_asset == nullptr)
    {
        Context.AddError(FText::FromString(TEXT("Required asset is null")));
        result = EDataValidationResult::Invalid;
        // Don't return early - check all conditions
    }

    if (_value < 0)
    {
        Context.AddError(FText::FromString(TEXT("Value must be >= 0")));
        result = EDataValidationResult::Invalid;
    }

    return result;
}
```

크래시 이슈가 아니면 바로 리턴하지 않고 모든 검사 수행 (패키징 시 모든 오류 확인 위함).
