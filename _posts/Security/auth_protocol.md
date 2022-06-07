
# OAuth 2.0
인증 *프레임워크*이다.

# SAML
인증 및 인가 정보를 담은 markup 언어로 SSO를 구현하기 위해 쓰이는 인증 *프로토콜*이다.
여기서 SSO는 예를 들어, 온프레미스에 이미 구축해 놓은 인증 시스템에서 인증하여 AWS 리소스에 접근할 수 있다.

### [SAML assertion](https://jumpcloud.com/blog/what-is-saml-assertion)
SAML assertion은 사용자가 누구인지, 사용자에 대한 정보, 액세스 권한을 기밀로 식별하는 IdP(Identity Provider)와 SP(Service Provider)간에 교환되는 메시지이다. 보안 조건과 assertion이 유효하다는 보증을 한다. SAML Request에 대해 SAML Response는 사용자 이름과 비밀번호 대신하여 전송된다.

## AWS와 연동
![](https://boomkim.github.io/images/saml-based-federation.diagram.png)

> 출처 : https://boomkim.github.io/2018/07/11/rough-draft-of-saml/

### [`AssumeRoleWithSAML`](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithSAML.html)
SAML 인증 응답을 통해 인증된 사용자에 대한 임시 보안 credential를 반환한다.

반환된 임시 보안 credential는 access key ID, secret access key, security token으로 구성된다.
이러한 임시 보안 credential를 통해 AWS 서비스 호출에 서명할 수 있다.

- 샘플 요청
```
https://sts.amazonaws.com/
?Version=2011-06-15
&Action=AssumeRoleWithSAML
&RoleArn=arn:aws:iam::123456789012:role/TestSaml
&PrincipalArn=arn:aws:iam::123456789012:saml-provider/SAML-test 
&SAMLAssertion=VERYLONGENCODEDASSERTIONEXAMPLExxxxxx...
```

- 샘플 응답
```
<AssumeRoleWithSAMLResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
    <AssumeRoleResult>
        <Issuer> https://integ.example.com/idp/shibboleth</Issuer>
        <AssumedRoleUser>
            <Arn>arn:aws:sts::123456789012:assumed-role/TestSaml</Arn>
            <AssumedRoleId>ARO456EXAMPLE789:TestSaml</AssumedRoleId>
        </AssumedRoleUser>
        <Credentials>
            <AccessKeyId>ASIAV3ZUEF...</AccessKeyId>
            <SecretAccessKey>8P+SQv...</SecretAccessKey>
            <SessionToken> IQoJb3JpZ2luX2VjEOz///////////...== </SessionToken>
            <Expiration>2019-11-01T20:26:47Z</Expiration>
        </Credentials>
        <Audience>https://signin.aws.amazon.com/saml</Audience>
        <SubjectType>transient</SubjectType>
        <PackedPolicySize>6</PackedPolicySize>
        <NameQualifier>SbdGOnUkh1i4+EXAMPLExL/jEvs=</NameQualifier>
        <SourceIdentity>SourceIdentityValue</SourceIdentity>
        <Subject>SamlExample</Subject>
    </AssumeRoleResult>
    <ResponseMetadata>
        <RequestId>c6104cbe-af31-11e0-8154-cbc7ccf896c7</RequestId>
    </ResponseMetadata>
</AssumeRoleWithSAMLResponse>
```

### [브라우저에서 SAML 응답 확인](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_saml_view-saml-response.html)

개발자 콘솔 - 네트워크 - 로그 보존을 선택한 후 로그인 후 SAML게시물을 찾아 SAMLReponse 속성을 찾는다.


## [OpenID Connect(OIDC) vs. SAML](https://gluu.org/oauth-vs-saml-vs-openid-connect)

- SAML에서 사용자는 로그인을 위해 SP에서 IdP로 redirect된다. 
- SAML에는 주체 정보, attribute, provider 및 인증 이벤트에 대한 정보가 포함된 XML문서인 *assertion*이 있다. OpenID Connect에는 제목, provider, 인증 정보가 포함된 JSON 형식의 id_token(*JWT*)으로 사용된다.
- SAML에서 back channel(application과 IdP/OP간의 직접 통신) 매커니즘을 정의하지만 실제로는 사용하지 않는다. SAML이 assertion을 전송하는 가장 일반적인 방법은 **브라우저**를 통하는 것이다. 대부분 POST binding을 사용하여 응답을 보낸다. OpenID Connect는 일반적으로 back channel(RP에서 OP를  직접 호출)을 사용한다. attribute는 토큰을 사용하여 REST API인 user_info endpoint를 호출하여 클라이언트에서 사용 가능하다.