---
layout: post
title: Keycloak을 활용한 User Federation 참고
categories: [Auth]
date: 2022-06-05
---

# AWS SAML based User Federation using Keycloak
[AWS SAML based User Federation using Keycloak](https://neuw.medium.com/ws-connect-saml-based-identity-provider-using-keycloak-9b3e6d0111e6) 기반으로 Keycloak을 활용한 AWS SAML 기반의 User Federation을 적용하였다. 다음의 과정이 포함된다.
- keycloak을 사용하여 AWS IAM에 SAML based Identity Provider를 추가한다.
- IdP를 통해 AWS에 federated user로 로그인할 수 있다.

SAML에서는 보통 브라우저를 통해 assertion을 전송한다. SAML Request에서 ProtocolBinding을 HTTP-POST로 지정하여 요청을 한다.

## Setup
로컬에서 빠르게 keycloak 서버를 띄우기 위해 docker로 간단하게 배포하였다.
```console
$ docker run -p 8080:8080 --rm --name keycloak-test -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:18.0.0 start-dev
```

1. keycloak에서 AWS를 client로 설정

    AWS를 client로 설정한다. keycloak에서 realm을 새로 생성해서 진행하는 것이 좋다. SAML metadata document를 사용하여 service provider(SP)로 AWS를 등록한다.
    - 우선 saml-metadata.xml를 다운받는다.
        ```bash
        curl -O https://signin.aws.amazon.com/static/saml-metadata.xml
        ```
    - <u>IDP Initiated SSO URL Name</u>는 `amazon-aws`으로 설정한다. Target IDP initiated SSO URL은 `/realms/{real-name}/protocol/saml/clients/{URL name}`형식으로 `/realms/aws/protocol/saml/clients/amazon-aws`으로 변환된다. 이와 동일하게 Base URL을 설정해준다.

        ![](img/2022-06-07-12-53-30.png)

    - scope에서 <u>Full Scope Allowed는 비활성화</u>한다.
    - AWS에서 설정하기 위해 SAML Metadata IDPSSODescriptor를 다운받는다.
        ```bash
        curl -o SAML-Metadata-IDPSSODescriptor.xml "http://localhost:8080/realms/aws/protocol/saml/descriptor"
        ```
2. AWS에서의 keycloak 연동을 위한 identity provider를 구성
    - identity provider 설정 시 위에서 받은 SAML-Metadata-IDPSSODescriptor.xml를 활용한다.

3. federation을 위한 AWS role 구성
    - SAML 2.0 federation을 기반으로 role을 생성한다.

4. Keycloak에서 users/groups/roles 등 mappings 구성
    - `https://aws.amazon.com/SAML/Attributes/Role`
    - `https://aws.amazon.com/SAML/Attributes/RoleSessionName`
    - `https://aws.amazon.com/SAML/Attributes/SessionDuration`

    **mapping이 누락되면 누락된 항목에 대해 오류가 발생**한다.
    ```
    RoleSessionName is required in AuthnResponse (Service: AWSSecurityTokenxxxx; Status Code: 400; Error Code: InvalidIdentityToken; Request ID: xxx; Proxy: null). Please try again.
    ```

### CLI 및 SDK를 사용한 프로그래밍 방식에서 사용 제한
[AWS CLI를 사용하여 AssumeRole을 호출하고 임시 사용자 자격 증명을 저장](https://aws.amazon.com/ko/premiumsupport/knowledge-center/aws-cli-call-store-saml-credentials/)을 참고하여 SAML에서 사용하는 assertion을 받아 터미널에서 인증하고자 한다.

브라우저에서 개발자 콘솔을 통해 SAML post 로그를 활용한다. 사전적으로 개발자 콘솔에서 SAML 패널이 없으면 따로 확장 프로그램을 추가한다.

![](img/2022-06-10-13-07-29.png)

saml 문서를 인코딩된 값인 SAMLResponse를 `samlresponse.log`에 저장하여 아래와 같이 AWS 임시 credential를 부여받는다. 
```
aws sts assume-role-with-saml --role-arn arn:aws:iam::123456789012:role/keycloak --principal-arn arn:aws:iam::123456789012:saml-provider/keycloak --saml-assertion file://samlresponse.log
```

여기서 다음과 같은 오류가 발생하였다.
```
An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithSAML operation: Invalid base64 SAMLResponse (Service: AWSOpenIdDiscoveryService; Status Code: 400; Error Code: AuthSamlInvalidSamlResponseException
```

이는 업로드한 연동 메타데이터 파일에 선언되어 있는 issuer와 SAML response의 issuer가 일치하지 않는 경우 발생할 수 있다고 한다. 메타데이터 파일은 IAM에서 IdP를 생성할 때 AWS에 업로드하는 파일이다.


# AWS user account OpenID federation using Keycloak

[AWS user account OpenID federation using Keycloak](https://neuw.medium.com/aws-account-openid-federation-using-keycloak-40d22b952a43) 참고하여 OpenID Connect 프로토콜을 이용하여 CLI나 SDK에서 인증받을 수 있도록 한다.  
SAML과 마찬가지로 AWS에서 Role을 기반으로 임시 credential를 사용한다. 

1. keycloak에서 AWS를 client로 설정
    - open-connect 프로토콜을 사용하여 client를 생성한다. 
    - 이후에 터미널에서 직접 로그인하는 경우. <u>direct access grants</u>가 비활성화되어 있으면 아래와 같이 오류가 발생하게 된다.

        ```
        {
            "error": "unauthorized_client",
            "error_description": "Client not allowed for direct access grants"
        }
        ```
        이를 해결하려면 settings에서 <u>direct access grants</u>를 활성화시켜야 한다. 

2. AWS에서의 keycloak 연동을 위한 identity provider 구성
    - OpenID Connect 기반의 Identity Provider를 생성하는데 Provider URL를 기입시 **provider의 HTTPS가 열려있어야 한다.** 아래와 같은 thumbprint를 인증해서 verify한다. 
    
        ![](img/2022-06-10-13-20-16.png)

3. federation을 위한 AWS role 구성
    - web identity를 기반으로 role을 생성한다.

4. Keycloak에서 users, groups, roles 등 mappings 구성
5. 터미널에서 `curl`을 통해 access token을 발급받는다.

    ```console
    $ token=$(curl -s "https://{keycloak-server-URL}/auth/realms/data/protocol/openid-connect/token" -d grant_type=password -d client_id="aws-open-id" -d client_secret={client-secret} -d username=test -d password=test)
    ```

6. 위의 토큰을 이용하여 AWS STS에서 [`AssumeWithWebIdentity`](https://docs.aws.amazon.com/ko_kr/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)를 이용하여 임시 credential를 부여받는다.

    ```
    aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/DEMO_OPEN_ID_READ_ONLY --web-identity-token $token --role-session-name keycloak
    ```
Keycloak endpoints는 [Accessing Keycloak Endpoints Using Postman](https://www.baeldung.com/postman-keycloak-endpoints)에서 확인할 수 있다.

python SDK를 사용하면 아래와 같이 사용할 수 있다.
```python
import boto.sts 
import boto.s3
import requests
import json

region = "us-east-1"

data = {
    'grant_type': 'password',
    'client_id': 'aws-open-id',
    'client_secret': client_secret,
    'username': 'test',
    'password': 'test',
}

response = requests.post('https://{keycloak-server-URL}/auth/realms/data/protocol/openid-connect/token', data=data)
access_token = json.loads(response.text)['access_token']

role_arn = "arn:aws:iam::123456789012:role/DEMO_OPEN_ID_READ_ONLY"
role_session_name = "keycloak"

conn = boto.sts.connect_to_region(region)
credentials = conn.assume_role_with_web_identity(role_arn, role_session_name, access_token).credentials    

s3conn = boto.s3.connect_to_region(region,
                     aws_access_key_id=credentials.access_key,
                     aws_secret_access_key=credentials.secret_key,
                     security_token=credentials.session_token)
 
buckets = s3conn.get_all_buckets()
 
print('Simple API example listing all S3 buckets:') # >> [bucket list]
```