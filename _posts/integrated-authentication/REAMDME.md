## Concepts
How to start using AWS Cognito  - Authorize, Authenticate and Federate user in [2021] 을 참고하여, 개념적으로 설명하면 authentication(인증)과 authorization(인가)을 포함한다. authentication은 identity, access에 대한 관리를 의미하며, **사용자가 누구인지**를 검증한다. 주로 Username, Password를 사용하거나 SSO를 통해 로그인하는 경우를 포함한다. authorization은 리소스에 접근하기 위한 **permission**을 제공하는 것을 의미한다. 

federation은 united, trusted relation을 의미한다.

![](./img/f728f94b-32d9-4e58-aa1c-0933b875120a.png)
> 페더레이션 아이덴티티란 무엇인가요? | Okta Identity Korea 

- identity federation : identity provider, service provider간에 사용자를 인증하고, authorization을 위한 정보를 전달하는 trust 시스템을 의미한다.  
- identity provider : 사용자 로그인 정보를 저장하고 관리한다.
- service provider : identity provider에 의해 제공된 인증 및 인가 정보를 기반으로 서비스를 제공한다.
- open standards : OIDC( OpenID Connect ), SAML, OAuth 2.0와 같은 공개 표준

### AWS Cognito
AWS Cognito User Pool은 authentication을 제공한다. 자체적으로 identity provider 역할을 하거나, Social identity provider, SAML identity provider를 사용하는 인증 방식이 있다.
