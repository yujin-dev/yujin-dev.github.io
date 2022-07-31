# [INFO] `git` 사용 - `rebase, `reset`
### `git rebase`
`git rebase`은 특정 branch와 HEAD를 맞추기 위한 git 명령어이다. MERGE작업이 많은 협업 코드 관리에서 필요성이 크다.

### `git reset`
git reset은 이미 COMMIT된 내역을 취소할 때 사용한다. 아래처럼

```bash
commit 00746c2cb668dd26c33af1dddee3fc979a60d9b3 (HEAD -> feature-branch)
...
commit b98d9ab6bf09ed9a463fcfb526e006ebf840c842 (origin/feature-branch)
...
commit aa7d7d7f17b162b611b9d81920db8ff7f298d4bb
...

# reset 적용 후
commit b98d9ab6bf09ed9a463fcfb526e006ebf840c842 (HEAD -> feature-branch, origin/feature-branch)
...
commit aa7d7d7f17b162b611b9d81920db8ff7f298d4bb
...
```

> [git add, commit, push 취소/변경/덮어쓰기(reset, revert, --amend)
](https://velog.io/@falling_star3/GitHub-git-add-git-commit-git-push-%EC%B7%A8%EC%86%8C%EB%B3%80%EA%B2%BD%EB%8D%AE%EC%96%B4%EC%93%B0%EA%B8%B0)

# [INFO] SCIM
Identity Provider와 Service Provider간에 User Identity 정보를 전송한다.
- REST( JSON ) 기반 프로토콜로 client, server를 정의한다.
- User CREATE/UPDATE/DELETE 이벤트가 발생하면 IdP에서 SCMI을 따라 SP에 자동으로 동기화된다.
- IdP에서 SP에서 Identity를 읽어와 User Directory에 추가한다.
 > [SCIM란?](https://www.okta.com/kr/blog/2017/01/what-is-scim/)
 
# [INFO] Keycloak - Event Logging 
Keycloak에서 user와 관련된 모든 이벤트는 기록될 수 있다. default로는 error 레벨 이벤트만 기록되나, 설정에서 storage를 활성할 수 있다.   
![](https://wjw465150.gitbooks.io/keycloak-documentation/content/server_admin/keycloak-images/login-events-settings.png)

event를 확인하려면 `Login Events`에서 가능하다.  
![](https://wjw465150.gitbooks.io/keycloak-documentation/content/server_admin/keycloak-images/login-events.png)

### Event Listener
Event Listener는 이벤트에 대해 listen하여 트리거 형식으로 action을 실행한다. 

> [Keycloak Login Events](https://wjw465150.gitbooks.io/keycloak-documentation/content/server_admin/topics/events/login.html)

# [INFO] Keycloak - OpenID Connect parameter
- Standard Flow Enabled : 인증 코드를 포함하여 redirect 기반 인증 여부(Authrization Code Flow)
- Implicit Flow Enabled : 인증 코드를 제외하여 redict 기반 인증 여부(Implicit Flow)
- Direct Access Grants Enabled : 사용자의 username/password 접근 허용 여부
- Service Account Enabled : access token 검색 허용 여부
- Authorization Enabled : client별 권한 부여 여부
- Root URL
- Valid Redirect URIs : login/logout 후에 브라우저가 redirect하는 URI
- Admin URL
- Web Origins : CORS origin을 허용할 URI
- Backchannel Logout Session Required : backchannel logout에서 logout token에 대한 session ID 포함 여부

> [Keycloak SSO 설정하기](https://freestrokes.tistory.com/153)  

# [INFO] Keycloak - First Login Flow
첫 로그인시 Github과 같은 외부 IdP를 통해 사용자 login을 설정할 수 있다. `Authentication` tab에서 가능하다.  
> https://github.com/keycloak/keycloak-documentation/blob/main/server_admin/topics/identity-broker/first-login-flow.adoc
> [Github as Identity Provider in Keycloak](https://medium.com/keycloak/github-as-identity-provider-in-keyclaok-dca95a9d80ca)

# [INFO] Lambda scheduling
AWS CloudWatch Events-Schedule을 통해 Lambda를 배치로 실행할 수 있다. Lambda는 월 1백만건 요청까지는 무료이다.  
> 참고 : [AWS Lambda 로 Cron Job 돌리기 ](https://medium.com/itus-project/aws-aws-lambda-%EB%A1%9C-cron-job-%EB%8F%8C%EB%A6%AC%EA%B8%B0-c1c8875dc288)

# [ERROR] `We were unable to update your App Configuration: client_credentials flow can not be selected if client does not have a client secret. (Service: AWSCognitoIdentityProviderService; Status Code: 400; Error Code: InvalidOAuthFlowException; Request ID: xxxx)`

AWS Cognito User Pool에서 resource server와 custom scope를 추가하여 해결 가능하다.
- resource server : access token이 포함된 application으로부터 인증된 요청을 처리한다.
- custom scope : resource server에 대한 API 호출을 정의한다.  
> [Amazon Cognito User Pools – Client Credentials](https://jobairkhan.com/2019/02/10/aws-cognito-user-pools-client-credentials/)

# [INFO] AWS Cognito - OAuth 2.0 grants types
### Authorization code grant
User Pool token이 직접적으로 사용하기 보다 authorization code를 통해 인증된다.
 
![](https://d2908q01vomqb2.cloudfront.net/0a57cb53ba59c46fc4b692527a38a87c78d84028/2018/11/08/auth_code_grant-1024x486.jpg)
- `https://AUTH_DOMAIN/oauth2/authorize`에 HTTP GET 요청한다. `response_type`=`code`
- CSRF 토큰은 쿠키로 반환된다. authentication page로 자동으로 redirect된다. 
- 1. `https://AUTH_DOMAIN/login`에 user credentials를 POST 요청하거나 2. 외부 IdP인 경우 해당 authencation page에서 `https://AUTH_DOMAIN/saml2/idpresponse`로 redirect된다.  
- Cognito에서 user pool credentials를 검증하거나 provider tokens/assertions를 받으면 `redirect_uri`에 세팅된 URL로 돌아간다.
- redirected URL에 호스팅되는 app은 query parameters에서 **authorization code를 추출하여 User Pool token으로 교환**한다. 교환은 ` https://AUTH_DOMAIN/oauth2/token`에 POST 요청을 통해 이루어진다. 
	- Authorization header는 `Basic BASE64(CLIENT_ID:CLIENT_SECRET)`로 설정된다. 
	- JSON response는 `id_token`( *scope에 openid가 추가된 경우에만 제공된다* ), `access_token`, `refresh_token`, `expires_in`, `token_type`이 반환된다. 

### Implicit grant
authorization code를 사용할 수 없는 상황에서 User Pool token을 직접 사용한다.

![](https://d2908q01vomqb2.cloudfront.net/0a57cb53ba59c46fc4b692527a38a87c78d84028/2018/11/08/implicit_grant-1024x483.jpg)
- `response_type`=`token`
- redirected URL에 호스팅되는 app은 query parameters에서 access toekn과 id token을 추출한다.

### Client credentials grant
application에 credentials를 부여하여 machine-to-machine간 요청을 허용한다.

![](https://d2908q01vomqb2.cloudfront.net/0a57cb53ba59c46fc4b692527a38a87c78d84028/2018/11/08/client_creds_grant-1024x661.jpg)
- `grant_type` : `client_credentials`
- Cognito authorization server로부터 JSON response에 `access_token`, `refresh_token`, `expires_in`, `token_type`이 반환된다.

> [Understanding Amazon Cognito user pool OAuth 2.0 grants](https://aws.amazon.com/ko/blogs/mobile/understanding-amazon-cognito-user-pool-oauth-2-0-grants/)

# [INFO] AWS Cognito - Using tokens with user pools
ID token은 authenticated user의 identity에 대한 claim를 포함하는 반면 access token은 authenticated user, user's groups, scopes에 대한 claim을 포함한다.
- 로그인이 성공하면 session을 만들고, ID, access, refresh token를 반환한다.

> [Using tokens with user pools](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-with-identity-providers.html)



