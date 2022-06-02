# Integraded Authentication

클라우드 내 데이터에 접근하기 위해 
1. 서버 - 클라이언트 형식으로 인증 서버를 매개로 토큰을 받아 사용하거나 
2. 데이터 소스에서 직접 받은 토큰을 로컬에 저장하여 사용하는
방식이 있다.

데이터 소스에서 직접 받은 토큰을 로컬에서 저장하여 사용하면 유저가 토큰 유출에 대한 위험도가 있고, 데이터 소스가 늘어날수록 관리해야 하는 계정도 늘어난다.

이에 대한 통합 인증 시스템이 필요하다.
- aws cognito
- cloud identity


## AWS Cognito + API Gateway + Lambda를 활용하여 리소스 접근
API Gateway는 User Pool 인증에서 토큰을 검증하고, 토큰을 사용하여 사용자에게 Lambda 함수나 자체 API를 비롯한 리소스에 대한 액세스 권한을 부여한다.  
![](https://docs.aws.amazon.com/ko_kr/cognito/latest/developerguide/images/scenario-api-gateway.png)

User Pool에 그룹을 사용하여 IAM 역할에 그룹 멤버쉽을 매핑하여 API Gateway를 통해 권한 제어가 가능하다.
- 사용자가 속한 그룹은 웹이나 모바일 앱 사용자가 로그인할 때 제공된 ID 토큰에 포함된다. 
- lambda 함수에서 확인을 위해 API Gateway에 대한 요청과 함께 User Pool에 대한 토큰을 제출한다.

### [사용자 풀에 그룹 추가](https://docs.aws.amazon.com/ko_kr/cognito/latest/developerguide/cognito-user-pools-user-groups.html)
User Pool에서 그룹을 생성 및 관리하고 사용자를 그룹에 추가하거나 제거할 수 있다. IAM 역할을 그룹에 할당하여 그룹 구성원에 대한 권한을 정의한다.

- 그룹을 사용하여 User Pool에서 사용자 모음을 생성할 수 있다. 
- 그룹과 관련된 IAM 역할을 사용하면 AWS S3에 특정 유저만 콘텐츠를 넣을 수 있는 등 다른 그룹에 대해 서로 다른 권한을 설정할 수 있다.  
IAM 역할에는 신뢰 정책과 권한 정책이 포함된다(신뢰 정책은 역할을 사용할 수 있는 사용자에 대한 것이고, 권한 정책은 그룹 구성원이 액세스할 수 있는 작업과 리소스에 대한 것이다).
- 그룹 구성원이 Cognito를 통해 로그인하면 identity pool에서 임시 자격 증명을 받을 수 있다. 이는 연결된 IAM 역할에 따라 결정된다. 


### [Amazon Cognito 사용자 풀을 권한 부여자로 사용하여 REST API에 대한 액세스 제어](https://docs.aws.amazon.com/ko_kr/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html)

API가 배포된 후 클라이언트는 
1. 먼저 User Pool에 로그인하고
2. 사용자의 자격 증명이나 엑세스 토큰을 획득한 다음 
3. `Authorization` 헤더로 설정되는 토큰을 사용하여 API 메서드를 호출한다.
API 호출은 토큰을 제출하고 유효한 경우에만 가능하다.

identity token은 로그인한 사용자의 *identity claim*을 기반으로 API 호출 권한을 부여하는데 사용된다. 
access token은 지정된 *사용자 지정 범위*를 기반으로 API 호출 권한을 부여하는데 사용된다.

API를 위한 Cognito User Pool을 생성하고 구성하려면
1. 기존의 User Pool을 사용하거나 Cognito User Pool을 생성한다.
2. User Pool이 포함된 API Gateway authorizer를 생성한다.
3. API로 authorizer를 활성화한다.
위와 같이 User Pool이 활성화되면 API 메서드를 호출하기 위해 API 클라이언트는
1. AWS Cognito를 통해 User Pool에 사용자 로그인하고 identity token 또는 access token을 획득한다.
2. API Gateway의 API를 호출하여 `Authorization` 헤더에서 토큰을 제출한다.

### 프로세스
![](https://miro.medium.com/max/1400/0*vXjRjS4vzOV9TFBh.)

> 출처:  
https://awskarthik82.medium.com/part-1-securing-aws-api-gateway-using-aws-cognito-oauth2-scopes-410e7fb4a4c0  

## SAML
인증 및 인가 정보를 담은 markup 언어로 SSO를 구현하기 위해 쓰인다.

여기서 SSO는 예를 들어, 온프레미스에 이미 구축해 놓은 인증 시스템에서 인증하여 AWS 리소스에 접근할 수 있다.

### AWS와 연동
![](https://boomkim.github.io/images/saml-based-federation.diagram.png)

> 출처 : https://boomkim.github.io/2018/07/11/rough-draft-of-saml/
