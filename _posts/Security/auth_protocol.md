
# OAuth 2.0
인증 *프레임워크*이다.

# SAML
인증 및 인가 정보를 담은 markup 언어로 SSO를 구현하기 위해 쓰이는 인증 *프로토콜*이다.
여기서 SSO는 예를 들어, 온프레미스에 이미 구축해 놓은 인증 시스템에서 인증하여 AWS 리소스에 접근할 수 있다.

![](https://developers.worksmobile.com/document/image/75_KR/158)

> 출처: [SAML 2.0 기반 SSO](https://developers.worksmobile.com/kr/document/2001070201?lang=ko)

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

# OpenID Connect

![](https://s-core.co.kr/wp-content/uploads/2021/01/72dsd.jpg)

1. 사전적으로 eBay에서 OP(OpenID Connect)를 사용하기 위해 인증이 가능하도록 등록을 하고 필요한 Client ID, Client Secret 같은 정보를 OP로부터 제공받은 상태이다.
2. eBay는 OP로부터 발급받은 Client ID를 비롯하여 Redirect URI, scope 등의 정보로 OP에 Authorization code를 요청한다.
3. OP는 authentication, authorization 여부를 판단하여 1회용 Authorization code를 eBay를 발급한다.
4. eBay는 전달 받은 code와 Client ID, Client Secret 등의 정보로 OP에 access token, id token을 요청한다.
5. OP는 access token, id token을 eBay에 전달한다.
6. eBay는 access token을 이용하여 다른 Resource Server 자원을 요청하게 된다. 

OpenID Connect는 access token과 함께 id token을 전달한다. 이 JWT(JSON Web Token)을 통해 암호화된 토큰 안에 user info를 비롯한 정보를 HTTP header의 최대 4KB 이내 저장할 수 있다. eBay는 access token을 사용하여 id token을 복호화하여 사용하게 된다.

id token은 Header.Payload.Signature로 `.`을 구분자로 하여 구성된다. Header에서는 서명 알고리즘 type(HS264, HS384, HS512 RSA264, RSA384, RSA512 등)을 선택할 수 있다.

> 출처: [편의성을 높인 ID 인증 관리: OIDC가 주목 받는 이유](https://s-core.co.kr/insight/view/%ED%8E%B8%EC%9D%98%EC%84%B1%EC%9D%84-%EB%86%92%EC%9D%B8-id-%EC%9D%B8%EC%A6%9D-%EA%B4%80%EB%A6%AC-oidc%EA%B0%80-%EC%A3%BC%EB%AA%A9-%EB%B0%9B%EB%8A%94-%EC%9D%B4%EC%9C%A0/)

## [OAuth 2.0과 OpenID Connect 정리](https://velog.io/@jakeseo_me/Oauth-2.0%EA%B3%BC-OpenID-Connect-%ED%94%84%EB%A1%9C%ED%86%A0%EC%BD%9C-%EC%A0%95%EB%A6%AC)
