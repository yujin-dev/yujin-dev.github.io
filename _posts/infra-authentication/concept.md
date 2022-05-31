# AWS Cognito
AWS Cognito를 통해 웹, 모바일 앱에서 손쉽게 사용자 가입, 로그인 및 액세스 제어가 가능하다.
수백만 사용자로 확장할 수 있고 Google, Facebook 같은 소셜 자격 증명 공급자와 SAML 2.0, OpenID Connect 같은 엔터프라이즈 자격 증명 공급자를 통한 로그인도 지원한다.  
managed service로 수백만 사용자로 확장 가능한 자격 증명을 제공하는 이점이 있다.

## User Pool & Identity Pool
![](https://docs.aws.amazon.com/ko_kr/cognito/latest/developerguide/images/scenario-cup-cib2.png)

1. user pool을 통해 로그인하여 인증 성공 후 토큰을 받는다.
2. identity pool을 통해 user pool 토큰을 AWS credential과 교환한다.
3. credential을 기반으로 AWS 서비스에 접근한다.

### User Pool
**User Pool**은 사용자 디렉토리이다. user pool의 사용자는 AWS Cognito나 IdP를 통해 페더레이션하여 웹이나 모바일 앱에 로그인한다.   
가입이나 로그인 관련 서비스를 여러 방식으로 제공하고 MFA, 이상 있는 credential 확인 등 보안 기능을 제공한다. AWS Lambda 트리거를 통해 사용자 지정 워크플로우나 사용자 migration도 가능하다. 

- 로그인 : 사용자는 User Pool을 통해 직접 로그인하거나 타사 자격 증명 공급자(IdP)를 통해 연동 로그인할 수 있다.
- 인증( 토큰 처리 ): Facebook, Google을 통한 소셜 로그인에서 받은 토큰과 OpenID Connect(OIDC) 및 SAML IdP에서 받은 토큰을 처리한다. 토큰을 받아 인증을 성공하면, 
	- 자체 서버 리소스나 Amazon API Gateway에 대한 액세스 권한을 부여할 수 있다.
	- AWS 자격 증명으로 토큰을 교환한다.
- 클라이언트 : 클라이언트 측 User Pool 토큰 처리는 Cognito SDK에서 제공한다. 


### Identity Pool
사용자는 **Identity Pool**을 통해 임시 AWS 자격 증명을 얻어 여러 AWS 서비스에 액세스할 수 있다. 
사용자의 고유한 credential을 만들고 자격 증명 공급자와 페더레이션할 수 있다. 

>출처  
https://docs.aws.amazon.com/ko_kr/cognito/latest/developerguide/what-is-amazon-cognito.html  
