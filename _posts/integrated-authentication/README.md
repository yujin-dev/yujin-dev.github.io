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

[AWS SAML based User Federation using Keycloak](https://neuw.medium.com/aws-connect-saml-based-identity-provider-using-keycloak-9b3e6d0111e6)를 참고하여 진행한다.


1. keycloak에서 AWS를 client로 설정

AWS를 client로 설정한다. keycloak에서 realm을 새로 생성해서 진행하는 것이 좋다. SAML metadata document를 사용하여 service provider(SP)로 AWS를 등록한다.  
```bash
# saml-metadata.xml 다운로드
curl -O https://signin.aws.amazon.com/static/saml-metadata.xml
```

```IDP Initiated SSO URL Name```에서 Target IDP initiated SSO URL은 `/realms/{real-name}/protocol/saml/clients/{URL name}`으로 구성되어 `amazon-aws`으로 설정하면 자동으로 `/realms/aws/protocol/saml/clients/amazon-aws`으로 변환되었다. 이에 따라 Base URL을 동일하게 설정해준다.

![](img/2022-06-07-12-53-30.png)

scope에서 Default Realm Roles이 추가되어 AWS Role 전달시 SAML오류가Full Scope Allowed는 비활성화한다.

AWS에서 설정하기 위해 SAML Metadata IDPSSODescriptor를 다운받는다.
```bash
curl -o SAML-Metadata-IDPSSODescriptor.xml "http://localhost:8080/realms/aws/protocol/saml/descriptor"
```
2. AWS에서의 keycloak연동을 위한 identity provider 구성

identity provider 설정 시 위에서 받은 SAML-Metadata-IDPSSODescriptor.xml를 활용한다.  

3. federation을 위한 AWS role 구성

SAML 2.0 federation을 기반으로 role을 생성한다.

4. Keycloak에서 users/groups/roles 등 mappings 구성
    - `https://aws.amazon.com/SAML/Attributes/Role`
    - `https://aws.amazon.com/SAML/Attributes/RoleSessionName`
    - `https://aws.amazon.com/SAML/Attributes/SessionDuration`

mapping이 누락되면 아래와 같은 오류가 발생한다.
```
RoleSessionName is required in AuthnResponse (Service: AWSSecurityTokenxxxx; Status Code: 400; Error Code: InvalidIdentityToken; Request ID: xxx; Proxy: null). Please try again.
```

