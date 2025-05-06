---
layout: post
title:  AWS Cognito - S3 연동
categories: [Auth]
date: 2022-06-21
---

# AWS Cognito - S3 연동
Cognito와 AWS S3를 연동하여 사용자 인증하는 과정을 정리하였다.

## Setup
1. Cognito User Pool을 생성한다  
    - [AWS Cognito - Snowflake 연동 | cognito-설정](https://qraftec.atlassian.net/wiki/spaces/QD/pages/151487112/AWS+Cognito+-+Snowflake#cognito-%EC%84%A4%EC%A0%95)를 참고한다.  
    **Generate client secret은 체크 해제**하여 client secret을 생성하지 않도록 한다.

2. Cognito Identity Pool을 생성한다. 
    ![](img/aws-cognito-1.png)
    - Unauthenticated identities : 체크하지 않아 인증되지 않은 사용자는 접근하지 못하도록 한다.
    - Authenticated identities : Allow Basic Flow으로 설정( 체크 )
    - Authentication providers : Cognito User Pool을 사용할 것이므로 적용할 User Pool ID, App client ID를 설정한다.

3. Role 생성 및 할당  
    S3 버킷에 대한 접근만 허용한다면 아래와 같이 policy를 설정하여 Role을 생성한다.
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:Get*",
                    "s3:List*",
                    "s3-object-lambda:Get*",
                    "s3-object-lambda:List*"
                ],
                "Resource": [
                    "*"
                ]
            }
        ]
    }
    ```
    
## Authentication 설정

1. User 생성
    - Cognito User Pool에서 user를 생성한다.
    - 편의를 위해 관리자 권한으로 사용자 비밀번호를 변경해주었다.  
        ```console
        aws cognito-idp admin-set-user-password --user-pool-id {USER_POOL_ID} --username {username} --password {password} --permanent
        ```

2. boto3 를 통해 S3 버킷에 접근  
    사용자 인증을 통해 받은 Id token을 기반으로 임시 credentials를 발급받는다.

    ```python
    import boto3

    session = boto3.Session(profile_name=os.environ["AWS_PROFILE"])
    client = session.client("cognito-idp")

    response = client.initiate_auth(
        ClientId=client_id,
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={"USERNAME": username, "PASSWORD": password},
    )  

    ci_client = boto3.client('cognito-identity')
    identityId = ci_client.get_id(
            IdentityPoolId="us-east-1:xxxxxxxxxxxxxxxxxxxxx",
            Logins={
                'cognito-idp.us-east-1.amazonaws.com/{}'.format(USER_POOL_ID): response['AuthenticationResult']['IdToken']
            }
        )['IdentityId']
        
    credentials = ci_client.get_credentials_for_identity(
            IdentityId=identityId,
            Logins={
                'cognito-idp.us-east-1.amazonaws.com/{}'.format(USER_POOL_ID): response['AuthenticationResult']['IdToken']
            }
        )['Credentials']
    ```

최종적으로 아래와 같은 credentials 정보가 반환된다.
```bash
# credentials
{
    'AccessKeyId': 'ASIA2ODGB55K...',
    'SecretKey': '+ByfPZIYcIj...',
    'SessionToken': 'IQoJb3JpZ2luX2VjEA0aCXVz........'
}
```

credentials를 기반으로 s3 bucket에 접근한다.

```console
> s3_client = session.client("s3", aws_access_key_id = credentials['AccessKeyId'], 
                                aws_secret_access_key = credentials['SecretKey'], 
                                aws_session_token = credentials['SessionToken'])
```
테스트로 s3 bucket list를 불러오면 json형태의 데이터가 반환된다.