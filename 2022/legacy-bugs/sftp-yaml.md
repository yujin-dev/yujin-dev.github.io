## sftp.yaml 파일 작성 오류

### [sftp.yaml](https://gist.github.com/jujhars13/1e99cf110e5df39d4ae3c7fef81589f8/stargazers) 배포시 버그 수정

**comment 참고할 것**

```
error: unable to recognize "sftp.yaml": no matches for kind "Deployment" in version "extensions/v1beta1"
```
이는 Deployment버전 extensions/v1beta1이 더 이상 사용되지 않으며 새 버전을 사용하기에 새 버전을 명시해야 한다.
➜ apiVersion: apps/v1 #extensions/v1beta1로 수정

```
error: error validating "sftp.yaml": error validating data: ValidationError(Deployment.spec): missing required field "selector" in io.k8s.api.apps.v1.DeploymentSpec; if you choose to ignore these errors, turn validation off with --validate=false
```
`selector`가 누락된 오류이다.

➜ 아래와 같이 추가
```
selector:
    matchLabels:
        app: sftp
```

[Kubernetes no matches for kind "deployment" in version "extensions/v1beta1" 에러 해결하기](https://velog.io/@makeitcloud/kubernetes-no-matches-for-kind-deployment-in-version-extensionsv1beta1-%EC%97%90%EB%9F%AC-%ED%95%B4%EA%B2%B0%ED%95%98%EA%B8%B0)