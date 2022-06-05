# Integraded Authentication

클라우드 내 데이터에 접근하기 위해 
1. 서버 - 클라이언트 형식으로 인증 서버를 매개로 토큰을 받아 사용하거나 
2. 데이터 소스에서 직접 받은 토큰을 로컬에 저장하여 사용하는
방식이 있다.

데이터 소스에서 직접 받은 토큰을 로컬에서 저장하여 사용하면 유저가 토큰 유출에 대한 위험도가 있고, 데이터 소스가 늘어날수록 관리해야 하는 계정도 늘어난다.

keycloak을 통해 aws 인증 시스템을 생성하고자 한다.
- keycloak을 사용하여 AWS IAM에 SAML based Identity Provider를 추가한다.
- IdP를 통해 AWS에 federated user로 로그인할 수 있다.


## POC
로컬에서 빠르게 keycloak 서버를 띄우기 위해 docker로 간단하게 배포하였다.
```console
$ docker run -p 8080:8080 --rm --name keycloak-test -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:18.0.0 start-dev
```

[AWS SAML based User Federation using Keycloak](https://neuw.medium.com/aws-connect-saml-based-identity-provider-using-keycloak-9b3e6d0111e6)과 [KeyCloak AWS SSO 연동](https://kyleyoon.tistory.com/3)를 참고하여 진행하였다.

크게는 
- AWS에서의 keycloak연동을 위한 identity provider 구성
- federation을 위한 AWS role 구성
- Keycloak에서 client 구성
- Keycloak User, Groups 등 구성

다른 점은 ```IDP Initiated SSO URL Name```에서 Target IDP initiated SSO URL은 `/realms/{real-name}/protocol/saml/clients/{URL name}`으로 구성되어 `amazon-aws`으로 설정하면 자동으로 `/realms/aws/protocol/saml/clients/amazon-aws`으로 변환되었다. 이에 따라 Base URL을 동일하게 설정해주었다.

이에 맞춰 SAML 파일은 `curl -o SAML-Metadata-IDPSSODescriptor.xml "http://localhost:8080/realms/aws/protocol/saml/descriptor"`에서 다운로드받아 진행하였다.

### bug report

과정을 완료 후 아래와 같은 오류가 발생하였다.
```
RoleSessionName is required in AuthnResponse (Service: AWSSecurityTokenxxxx; Status Code: 400; Error Code: InvalidIdentityToken; Request ID: xxx; Proxy: null). Please try again.
```