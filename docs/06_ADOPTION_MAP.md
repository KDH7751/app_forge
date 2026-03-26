# Adoption Map

## 목적

이 문서는 앞으로 Engine이나 공통 layer로 흡수할 수 있는 요소를 정리한다.

현재 구현의 source of truth를 정의하는 문서가 아니라,
재사용 후보와 우선순위를 기록하는 문서다.

## Must

- Engine public API barrel
- Routing DSL
- RouterEngine
- NavigationState
- EngineShell
- FeatureShell

## Should

- logger / error reporting port
- secure/local storage wrapper
- auth session contract
- Result / AppError core type

## Could

- Firebase 외 backend를 위한 generic network layer
- analytics / observe abstraction
- reusable feature scaffolding helper

## 원칙

- Engine으로 올리는 기준은 “여러 앱에서 반복되는가”이다.
- 제품 policy가 강한 코드는 Engine으로 올리지 않는다.
- 재사용성보다 설정 비용이 커지면 Engine 흡수를 다시 검토한다.