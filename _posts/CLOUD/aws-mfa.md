## [IAM의 임시 보안 자격 증명](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_credentials_temp.html)
AWS Security Token Service(AWS STS)를 사용하면 AWS 리소스에 대한 액세스를 제어할 수 있는 임시 credential를 
생성하여 사용자에게 제공한다.


## [AWS 리소스에서 임시 자격 증명 사용](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_credentials_temp_use-resources.html)

- 임시 credential을 사용해 호출할 경우 세션 토큰이 포함되어야 한다.
- 임시 credential은 지정된 Expiration 날짜 이후에 만료된다. 

### aws-cli에서 임시 보안 자격 증명 사용하기
`AssumeRole`, `GetFederationToken`과 같은 aws sts api를 호출하여 결과값을 사용할 수 있다. 

아래는 `AssumeRole`에 대한 호출로 role을 수임할 권한이 있는 IAM 사용자의 자격 증명을 참조한다.
```console
$ aws sts assume-role --role-arn arn:aws:iam::123456789012:role/role-name --role-session-name "RoleSession1" --profile IAM-user-name > assume-role-output.txt
```

### AWS Configure with MFA
MFA를 추가하면서 `aws configure`에서도 인증을 추가해줘야 한다.

**[`get-session-token`](https://docs.aws.amazon.com/cli/latest/reference/sts/get-session-token.html)**

- AWS 계정이나 IAM 사용자의 임시 credential을 반환하는 명령어이다. 
- MFA를 이용하여 AWS API operation을 사용할 경우 적용한다.
- MFA-enabled 사용자는 MFA device와 연동한 MFA 코드를 제출하여 `GetSessionToken`을 호출해야 한다.

```console
$ aws sts get-session-token \
    --duration-seconds 900 \
    --serial-number "YourMFADeviceSerialNumber" \
    --token-code 123456

{
    "Credentials": {
        "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
        "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY",
        "SessionToken": "AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4OlgkBN9bkUDNCJiBeb/AXlzBBko7b15fjrBs2+cTQtpZ3CYWFXG8C5zqx37wnOE49mRl/+OtkIKGO7fAE",
        "Expiration": "2020-05-19T18:06:10+00:00"
    }
}
```


[MFA 상태 확인](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_credentials_mfa_checking-status.html)에서 `YourMFADeviceSerialNumber`을 확인할 수 있다.(AWS 콘솔에서만 확인이 가능하다)
`token-code`는 MFA 기기에서 authenticator 코드를 입력한다.

[AWS CLI에서 MFA 임시세션토큰 자동화](https://junhyeong-jang.tistory.com/4)]를 참고하여 AWS profile에서 MFA 임시세션토큰을 등록한다.

보통은 aws cli로 작업할 때 임시세션토큰이 아닌 access key + secret key로 이루어진 장기 credential을 사용한다. 하지만 장기 credential에는 MultiFactorAuthPresent 키가 없다.

따라서 위에서 언급한 `GetSessionToken` API를 호출해서 임시 credential을 주기적으로 발급받아야 한다. 코드를 작성해 자동으로 등록하거나, console 사용자와 cli 사용자를 따로 생성하거나 사용자의 MFA 활성화가 확인된 경우에는 MFAForcePolicy를 제외시킨다. 

AWS CLI configure 수정을 위한 경로는 `~/.aws`에서 진행한다.

1. ` ~/.aws/config`에서 `mfa_arn`과 계정 정보 매핑을 위한 `source_profile` 을 추가한다.
```console
$ vi  ~/.aws/config

[default]
region = us-east-1

[profile mfa]
mfa_arn = arn:aws:iam::123456789012:mfa/my_name
source_profile = mfa
region = us-east-1
```

2. ` ~/.aws/credentials`에 MFA 인증을 통해 발급된 임시 Access-key 와 Secret-Access-Key, Session-Token을 등록한다. 위에서 실행한 `aws sts get-session-token`을 통해 발급된 정보를 이용한다.
```console
$ vi ~/.aws/credentials

[default]
aws_access_key_id = 
aws_secret_access_key = 

[mfa]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY
aws_session_token = AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4OlgkBN9bkUDNCJiBeb/AXlzBBko7b15fjrBs2+cTQtpZ3CYWFXG8C5zqx37wnOE49mRl/+OtkIKGO7fAE
```

3. `export AWS_DEFAULT_PROFILE=mfa`를 적용하면 default로 `mfa` profile을 사용한다.
4. aws s3 버킷을 가져올 수 있는지 테스트한다.

기존에 자격 증명이 되어 있지 않으면 아래와 같이 Access Denied가 발생한다.

```console
$ aws s3 ls #--profile mfa

An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
```

자격 증명이 완료된 후에는 aws s3 버킷 목록을 제대로 가져온다.

## MFA force policy
MFA가 활성화된 사용자만 부여된 권한을 사용할 수 있도록 설정하는 정책이다.
MFA를 강제적으로 적용하도록 policy를 생성하여 IAM user에게 attach하여 적용한다.

MFA **인증** 여부를 기반으로 Resource에 대한 접근이 허용되기에 로그아웃 후 재로그인하여 인증을 거쳐야 정상적으로 부여된 권한을 사용할 수 있다.
