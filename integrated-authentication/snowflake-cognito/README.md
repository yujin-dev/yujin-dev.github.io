# AWS Cognito - Snowflake 연동

Cognito와 Snowflake를 연동하여 사용자를 관리한다. 

> 참고 : [AWS COGNITO AS CUSTOM OAUTH PROVIDER WITH SNOWFLAKE](https://community.snowflake.com/s/article/How-to-use-AWS-Cognito-and-Lambda-to-generate-a-Authorization-token-and-use-Scopes-for-Oauth-with-Snowflake)

## cognito 설정
#### 1. Cognito User Pool을 생성한다.
#### 2. User Pool App Client를 생성한다. 
Id token을 사용하기 위해 아래와 같이 설정해준다. 

- Enabled Identity Providers : Cognito User Pool
- Callback URL(s), Sign out URL(s) : 로그인 후 redirect할 URL을 설정해준다.( redirect가 가능하다면 어떤 것이든 상관없음 )
- Allowed OAuth Flows : Authorization code grant, Implicit grant
- Allowed OAuth Scopes : email, openid

![](./../img/eb657233-edba-4549-b996-4039ab55d9f4.png)

#### 3. lambda function을 생성한다.
Id token을 생성하기 전에 JWT의 claim값을 변경해줘야 한다. Snowflake에서 JWT를 확인할 때 role에 관한 정보가 없으면 에러가 발생한다. 따라서 scope에 추가적으로 role을 설정한다.  

- Lambda function name : customize-token
- Lambda 함수 작성 : Id token을 cutomize하기 위해 아래와 같이 Lambda 함수를 구성한다. 

```pyhon
def lambda_handler(event, context):
    """
    This function handles adding a custom claim to the cognito ID token.
    """

    # grab requestor's email address
    print(event)
    email = event['request']['userAttributes']['email']
    import time
    nbf = int(time.time())
    upn = event['request']['userAttributes']['email'].upper()

    # placeholder variable
    pet_preference = ''

    # set preference to 'snowflake' if email contains @snowflake.com
    # otherwise preference is 'datawarehousing'
    if "@snowflake.com" in email:
        pet_preference = 'snowflake'
    else:
        pet_preference = 'datawarehousing'

    # this allows us to override claims in the id token
    # "claimsToAddOrOverride" is the important part
    event["response"]["claimsOverrideDetails"] = {
        "claimsToAddOrOverride": {
            "scp": "session:role:testoauth",
            "scope": "session:role:testoauth"#,
            # "nbf": nbf,
            # "upn": upn
            }
         }
    print(event)
    # return modified ID token to Amazon Cognito
    return event
```

cognito에서 lambda를 실행할 수 있도록 Role을 생성한다.

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cognito-idp.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

위에서 생성한 role을 lambda Function의 Configuration에서 Execution Role로 설정한다.

#### 4. Cognito User Pool의 Pre Token Generation으로 위에서 생성한 lambda 함수( `customize-token` )를 설정한다
![](./../img/f19f3f97-c920-4f72-bc4a-50c3424d9fc1.png)

#### 5. 추가적으로 Domain Name을 설정할 수 있다. 
```
[ bug report ]

domain name을 설정하지 않으면 이후 authorization 과정에서 오류가 발생한다.
```


## snowflake 설정
Cognito 설정이 완료되면 OpenID Connect Discovery URL에 접속하여 관련된 endpoint 정보를 확인할 수 있다.

```
$ curl -s https://cognito-idp.us-east-1.amazonaws.com/us-east-1_CCxelpahg/.well-known/openid-configuration | jq -r
------------------------
{
  "authorization_endpoint": "https://datatest.auth.us-east-1.amazoncognito.com/oauth2/authorize",
  "id_token_signing_alg_values_supported": [
    "RS256"
  ],
  "issuer": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_CCxelpahg",
  "jwks_uri": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_CCxelpahg/.well-known/jwks.json",
  "response_types_supported": [
    "code",
    "token"
  ],
  "scopes_supported": [
    "openid",
    "email",
    "phone",
    "profile"
  ],
  "subject_types_supported": [
    "public"
  ],
  "token_endpoint": "https://datatest.auth.us-east-1.amazoncognito.com/oauth2/token",
  "token_endpoint_auth_methods_supported": [
    "client_secret_basic",
    "client_secret_post"
  ],
  "userinfo_endpoint": "https://datatest.auth.us-east-1.amazoncognito.com/oauth2/userInfo"
}
```

### 1. AWS에서 Cognito Issuer Public Key를 발급받는다.
- AWS  CLI를 통해( Cognito resources에 대한 credential이 설정되어 있어야 함 ) certificate를 받는다. 
    ```
    $ aws cognito-idp get-signing-certificate --user-pool-id us-east-1_CCxelpahg
    {
        "Certificate": "MIICvTCCAaWgAwIBA...."
    }
    ```
- certificate 정보를 아래와 같은 형식으로 cert.pem로 저장한다.
    ```
    -----BEGIN CERTIFICATE-----
    MIICvTCCAaWgAwIBA....
    -----END CERTIFICATE-----
    ```

- pem 파일로부터 openssl 로 public key를 파생시킨다. public key는 snowflake external oauth 설정에서 필요하다.
    ```
    $ openssl x509 -pubkey -noout -in cert.pem < cert.pem | grep -vE "BEGIN|END" | tr -d '\n' ; echo
    -------------
    MIIBIjANBgkqhkiG9.....
    ```
#### 2. Snowflake에서 Security Integration을 생성한다.
```
CREATE OR REPLACE security integration external_oauth_custom
type = external_oauth
enabled = true
external_oauth_type = custom
external_oauth_issuer = 'https://cognito-idp.us-east-1.amazonaws.com/us-east-1_CCxelpahg'
external_oauth_rsa_public_key = 'MIIBIjANBgkqhkiG9.....'
external_oauth_audience_list = ('5m0eenjjbhknapn9ku44imrl8j')
external_oauth_scope_mapping_attribute = 'scp'
external_oauth_token_user_mapping_claim = 'email'
external_oauth_any_role_mode = 'ENABLE'
external_oauth_snowflake_user_mapping_attribute = 'login_name';
```

- `external_oauth_issuer` : issuer endpoint( OpenID Connect Discovery URL에서도 확인 가능 )
- `external_oauth_rsa_public_key` : 위에서 생성한 public key 값
- `external_oauth_audience_list` : App client ID
- `external_oauth_snowflake_user_mapping_attribute` : 해당 속성값을 통해 매칭하여 확인하므로 login_name과 인증하는 username이 동일해야 한다.( 여기서 email로 매칭된다.)

## Authentication
### User 생성
- cognito user pool에서 user를 생성한다. Snowflake에서 사용자를 email를 기반으로 매칭시키기 때문에 **email 주소가 있어야 한다.**
- Snowflake에서 User를 생성할 때는 `login_name`을 **email 주소로 등록**한다.
    ```
    create user yujinlee
    login_name='yujin.lee@naver.com'
    display_name='yujin.lee'
    email='yujin.lee@naver.com'
    ```
- testoauth 라는 role을 추가한다.
    ```
    create role testoauth;
    grant role testoauth to role public;
    grant role testoauth to user yujinlee;
    ```
### Authorization Token 생성
- 권한 확인을 위해 인증 코드를 `https://<Cognito_User_Pool_Domain>/login?response_type=code&scope=openid%email&client_id=<Cognito App Client ID>&redirect_uri=<Redirect URL>`형식의 URL에서 발급받는다. redirect_uri 은 App client에서 설정한 Callback URL과 동일해야 한다. 
- `FORCE_CHANGE_PASSWORD`가 True로 고정되어 있어, 편의를 위해 password를 직접 바꿔주었다.
    ```
    aws cognito-idp admin-set-user-password --user-pool-id us-east-1_CCxelpahg --username yujin.lee@naver.com --password 987654321 --permanent
    ```
    브라우저에서 https://datatest.auth.us-east-1.amazoncognito.com/login?client_id=627aj40llfm8omle94ovmksjp4&redirect_uri=https://example.com/&response_type=code를 접속한다. 
    
    ![](./../img/8da930d6-caac-4067-bd66-6bf2f898f0f7.png)
    로그인이 성공하면 위와 같이 code가 반환됨
    
    ```markdown
    [bug report]

    # todo
    - cognito userpool 생성 시 설정한, 또는 설정된 client_id, redirect_url 값이 동일하지 않으면 로그인 화면이 뜨지 않는다.
    - username, password으로 첫 로그인 시, 비밀번호를 바꾸라는 prompt 창이 뜬다. 비밀번호를 바꾸면 ERROR가 뜨면서 code가 반환되지 않는 문제가 있었다.
    ```

위에서 확인한 Authorization code을 사용하여 Access token을 받는다.
```python
import requests
import json
import os
from requests.auth import HTTPBasicAuth

url = "https://datatest.auth.us-east-1.amazoncognito.com/oauth2/token"
headers = {"Content-Type": "application/x-www-form-urlencoded"}
client_id= "627aj40llfm8omle94ovmksjp4"
client_secret = "7197el6ecofiv......"

def get_token(authorization_code):
    data = {"grant_type": "authorization_code", "client_id": client_id, "code": authorization_code, "redirect_uri": "https://example.com/"}
    response = requests.post(url, auth=HTTPBasicAuth(client_id, client_secret), data=data, headers=headers)
    print(response.status_code)
    return json.loads(response.content)
```
여기서 `HTTPBasicAuth(client_id, client_secret)`을 통해 `{client_id}:{client_secret}`값이 base64 인코딩되어 요청에 전송된다.
```
>> response = get_token(authorization_code="7d23326c-796f-4304-ab30-bccecf466e89")
>> response
-----------------------
{'id_token': 'eyJraWQiOxxxxxx.eyJhdF9oYXxxxxx.eBcGMWxxxxx',
 'access_token': 'eyJraWQiO..........',
 'refresh_token': 'eyJjdHkiO...........',
 'expires_in': 3600,
 'token_type': 'Bearer'}
```
```
[bug report]

몇 가지 오류 상황이 있다.
- invalid_client
- unauthorized_client
- invalid_grant : Authorization code는 일회성으로, 반복해서 사용할 경우 오류가 발생한다.
- internal_error : 서버 측(여기서는 cognito)에서 내부적으로 에러가 발생하여 인증되지 않는다. 이번 경우에는 pre token generator에서 설정한 lambda handler가 제대로 작동하지 않아 id token이 발급되지 않았었다. lambda function을 수정하여 해결하였다.
```
#### ***ID token*** 
id_token은 JWT(JSON Web Token)을 인코딩한 값으로 [jwt.io](https://jwt.io/)에서 확인하여 디코딩된 내용을 확인할 수 있다.

![](./../img/2022-06-23-10-33-05.png)

- lambda handler에서 설정한 `scope`, `scp` claims를 payload에서 확인할 수 있다. snowflake에 해당 token을 전송하면 명시된 role을 사용하도록 한다.

### id token을 사용하여 Snowflake에 연결
최종적으로, oauth 인증을 통해 위에서 확인한 id_token 을 사용하여 snowflake에 연결한다. password를 설정하지 않고 token을 통해 인증이 가능한 것을 확인할 수 있다.
```python
import snowflake.connector
import json

ctx = snowflake.connector.connect(
    user='yujin.lee@naver.com',
    account= os.environ['ACCOUNT'],
    database= os.environ['DATABASE'], 
    schema= os.environ['SCHEMA'],
    warehouse= os.environ['WAREHOUSE'],
    role = "testoauth",
    authenticator='oauth',
    token=response["id_token"] # 'eyJraWQiOxxxxxx.eyJhdF9oYXxxxxx.eBcGMWxxxxx'
    )

cs = ctx.cursor()
cs.execute("SELECT current_version()")
print(cs.fetchall())
```
```
[bug report]

아래와 같이 role을 부여할 수 없다는 오류가 발생한다.

id token의 claims에 role을 명시하였으나, snowflake에서 유저에 해당 role에 대한 권한이 없거나 role이 존재하지 않기 때문이다. testoauth라는 role을 snowflake에서 정의하여 해결하였다.
```

>> references
- error handling : [AWS Cognito Token with Authorization Code Grant PKCE returns {"error":"invalid_grant"}](https://stackoverflow.com/questions/63258246/aws-cognito-token-with-authorization-code-grant-pkce-returns-errorinvalid-g)
- [Token endpoint](https://docs.aws.amazon.com/cognito/latest/developerguide/token-endpoint.html)