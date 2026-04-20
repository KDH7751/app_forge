# Adoption Map

## 목적

이 문서는 앞으로 Engine이나 공통 layer로 흡수할 수 있는 후보를 기록한다.
현재 구조의 source of truth나 잠긴 결정을 정의하는 문서는 아니다.

## 후보 분류

### Must

- Engine public API barrel
- Routing DSL
- RouterEngine
- NavigationState
- EngineShell
- FeatureShell

### Should

- logger / error reporting port
- secure/local storage wrapper
- auth session contract
- Result / AppFailure core type

### Could

- Firebase 외 backend를 위한 generic network layer
- analytics / observe abstraction
- reusable feature scaffolding helper

## 판단 기준

- 여러 앱에서 반복되는가
- 제품 policy가 강하게 묻어 있지 않은가
- 재사용 이득이 설정 비용보다 큰가
- Engine이나 공통 layer로 올려도 현재 경계를 흐리지 않는가

## 범위 경계

- 이 문서는 “지금 옮긴다”를 뜻하지 않는다.
- 후보가 있다고 해서 현재 구조 결정을 다시 여는 것은 아니다.
- 실제 승격 여부는 별도 결정 문서에서 잠근다.
