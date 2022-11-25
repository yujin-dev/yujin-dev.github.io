# [Flytectl](https://github.com/flyteorg/flytectl)

## Usage
### setup
configuration은 다음과 같이 설정할 수 있다.
```bash
admin:
  endpoint: dns:///localhost:30081
  insecure: true # Set to false to enable TLS/SSL connection (not recommended except on local sandbox deployment).
  authType: Pkce # authType: Pkce # if using authentication or just drop this.
```
### verbs
- `flytectl compile` 
- `flytectl completion`
- `flytectl config`
- `flytectl create`
- `flytectl delete`
- `flytectl demo`
- `flytectl get`
- `flytectl register`
- `flytectl sandbox`
- `flytectl update`
- `flytectl upgrade`
- `flytectl version`