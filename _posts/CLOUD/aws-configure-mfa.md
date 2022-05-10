# AWS Configure with MFA
MFA를 추가하면서 `aws configure`에서도 인증을 추가해줘야 한다.

### [IAM의 임시 보안 자격 증명](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_credentials_temp.html)
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

### [`get-session-token`](https://docs.aws.amazon.com/cli/latest/reference/sts/get-session-token.html)
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


