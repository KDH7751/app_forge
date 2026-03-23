# Adoption Map

## Must

- Engine public API barrel
- 이후 Phase에서 도입할 Routing DSL과 navigation state
- Engine이 소유하는 재사용 가능한 shell 구조

## Should

- `engine/observe` 아래의 logger와 error reporting port
- `engine/storage` 아래의 secure/local storage wrapper

## Could

- Firebase 외의 backend가 필요해질 경우를 대비한 generic network layer
