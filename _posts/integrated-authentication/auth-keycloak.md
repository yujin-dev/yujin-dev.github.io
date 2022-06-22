
# KeyCloak
국제적인 인증, 인가 표(SAML, OAuth 2.0 등)을 모두 제공하는 오픈소스로 Kubernetes, MSA 환경에 최적화된 솔루션이다.
- SSO
- ID 중개 및 소셜 로그인
- 관리자/계정관리 콘솔
- 표준 프로토콜( OpenID Connect + OAuth 2.0, SAML ) 지원
- 기본적으로 Java 기반의 H2 DB를 제공한다. 
- 세분화된 권한 부여 정책 및 다양한 액세스 제어 매커니즘으로 리소스 보호
	- Attribute-Based-Access-Contorl
	- Role-Based-Access-Control
	- User-Based-Access-Control
	- Context-Based-Access-Control
	- Rule-Based-Access-Control
	- Time-Based-Access-Control
- 중앙 집중형 정책 결정 
- REST 기반
- 권한 부여 워크플로 및 사용자 관리 액세스

리소스는 keycloak 관리 콘솔이나 protection API를 통해 관리 가능하다. 

### 인증 서비스
권한 부여 서비스는 RESTfull 엔드포인트로 구성된다.
- 토큰 엔드포인트 : 서버에서 액세스 토큰을 얻어 리소스에 액세스할 수 있다. 
- 리소스 관리 엔드포인트
- 권한 관리 엔드포인트 

### OpenID Connect(OIDC) vs. OAuth 2.0
keycloak은 인증 방식이 OAuth 2.0을 기반으로 한 OIDC이다.
- OIDC : Oauth 2.0의 확장 인증 프로토콜로, 인증에 초점을 맞춘다.
- OAuth 2.0 : 데이터에 대한 액세스 권한 부여에 초점을 맞춘다.

### Google Cloud SSO
SAML 제휴를 통해 KeyCloak과 Cloud ID/Google workspace 계정 간에 SSO를 설정할 수 있다.

다음과 같이 KeyCloak 서버를 구성한다.
- Client ID : `google.com`
	- Name : `Google Cloud`
	- Sign Assertions : 사용
    ..
- Client Protocol : SAML
- Client SAML endpoint : -

## architecture
keycloak은 모든 메타 데이터, 구성을 관리할 수 있는 네임스페이스와 같다.   
![](https://developers.redhat.com/sites/default/files/styles/article_floated/public/blog/2019/11/keycloak1.png?itok=dlMycurG)


### 프로세스
![](https://sp-ao.shortpixel.ai/client/to_auto,q_lossless,ret_img,w_765,h_484/https://www.comakeit.com/wp-content/uploads/keycloak-1.jpg)
> 출처  
https://alice-secreta.tistory.com/28  
https://www.keycloak.org/docs/latest/authorization_services/#_overview_architecture  
https://www.comakeit.com/blog/quick-guide-using-keycloak-identity-access-management/  
https://developers.redhat.com/blog/2019/12/11/keycloak-core-concepts-of-open-source-identity-and-access-management#wrapping_up
