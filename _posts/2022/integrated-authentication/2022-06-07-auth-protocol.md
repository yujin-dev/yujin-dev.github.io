---
layout: post
title: SAML and OpenID Connect
categories: [Auth]
date: 2022-06-07
---

# SAML
**SAML**이란 인증 및 인가 정보를 담은 마크업 언어로 SSO를 구현하기 위해 쓰이는 <u>인증  프로토콜</u>이다.( 참고: **OAuth 2.0**은 <u>인증 프레임워크</u> )
SSO를 통해 온프레미스에 이미 구축해 놓은 인증 시스템에서 인증하여 AWS 리소스에 접근할 수 있다.

![](https://developers.worksmobile.com/document/image/75_KR/158)

**SAML Assertion**은 사용자가 누구인지, 사용자에 대한 정보, 액세스 권한을 기밀로 식별하는 <u>IdP(Identity Provider)와 SP(Service Provider)간에 교환되는 메시지</u>이다. 
- 보안 조건과 assertion이 유효하다는 보증을 한다. 
- SAML Request에 대한 응답으로 SAML Response는 사용자 이름과 비밀번호 대신하여 전송된다.

## AWS와 연동
![](https://boomkim.github.io/images/saml-based-federation.diagram.png)

**AssumeRoleWithSAML**은 SAML 인증 응답을 거쳐 인증된 사용자의 임시 보안 credential를 반환한다. 임시 보안 credentials을 받아 AWS 서비스 호출에 서명할 수 있다.  
반환된 임시 보안 credential는 `access key ID`, `secret access key`, `security token`으로 구성된다.

### EXAMPLE SAML REQUEST
```
https://sts.amazonaws.com/
?Version=2011-06-15
&Action=AssumeRoleWithSAML
&RoleArn=arn:aws:iam::123456789012:role/TestSaml
&PrincipalArn=arn:aws:iam::123456789012:saml-provider/SAML-test 
&SAMLAssertion=VERYLONGENCODEDASSERTIONEXAMPLExxxxxx...
```

### EXAMPLE SAML RESPONSE
```xml
<AssumeRoleWithSAMLResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
    <AssumeRoleResult>
        <Issuer> https://integ.example.com/idp/shibboleth</Issuer>
        <AssumedRoleUser>
            <Arn>arn:aws:sts::123456789012:assumed-role/TestSaml</Arn>
            <AssumedRoleId>ARO456EXXXXXXXX:TestSaml</AssumedRoleId>
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

### [ 참고 ] 브라우저에서 SAML 응답 확인하기
개발자 콘솔 - 네트워크 - 로그 보존을 선택한 후 로그인 후 SAML게시물을 찾아 SAMLReponse 속성을 찾아 확인 가능하다.

# OpenID Connect

![](https://s-core.co.kr/wp-content/uploads/2021/01/72dsd.jpg)

- Resource Proivder : eBay
- OpenID Connect : Google

인 경우를 예시로 보자.

1. 사전에 eBay에서 OP(OpenID Connect)를 사용하기 위해 인증이 가능하도록 해놓고 필요한 **Client ID, Client Secret** 같은 정보를 OP로부터 제공받는다.

2. eBay는 OP로부터 발급받은 Client ID를 비롯하여 Redirect URI, scope 등의 정보로 OP에 **Authorization code**를 요청한다.

3. OP는 authentication, authorization 여부를 판단하여 **1회용 Authorization code**를 eBay를 발급한다.

4. eBay는 전달 받은 code와 Client ID, Client Secret 등의 정보로 OP에 **access token, id token**을 요청한다.

5. OP는 **access token, id token**을 eBay에 전달한다.

6. eBay는 access token을 이용하여 다른 Resource Server 자원을 요청하게 된다.  
OP는 access token과 함께 id token을 전달한다. 이 **JWT**(JSON Web Token)에 암호화된 토큰 안에 user info를 비롯한 정보를 HTTP header의 최대 4KB 이내 저장할 수 있다. <u>eBay는 access token을 사용하여 id token을 복호화</u>하여 사용하게 된다.  
id token은 `Header.Payload.Signature`로 `.`을 구분자로 하여 구성된다. Header에서는 서명 알고리즘 type(HS264, HS384, HS512 RSA264, RSA384, RSA512 등)을 선택할 수 있다.

## OpenID Connect vs. SAML

- **SAML**에서 사용자는 로그인을 위해 SP에서 IdP로 redirect된다. 
- 인증 포맷
    - **SAML**에는 주체 정보, attribute, provider 및 인증 이벤트에 대한 정보가 포함된 <u>XML문서인 assertion</u>를 이용한다. 
    - **OpenID Connect**에서는 제목, provider, 인증 정보가 포함된 <u>JSON 형식의 id_token(JWT)</u>이 적용된다.
- back channel 활용
    - **SAML**에서 어플리케이션의 IdP 또는 OP간의 직접 통신하는 back channel 매커니즘을 정의하긴 하지만, <u>실제로는 사용하지 않는다</u>. **SAML**이 <u>assertion을 전송하는 가장 일반적인 방법은 브라우저를 통하는 것</u>이다. 대부분 POST binding을 사용하여 응답을 보낸다. 
    - **OpenID Connect**는 일반적으로 RP에서 OP를 직접 호출하는 back channel을 사용한다. <u>토큰을 통해 REST API인 user_info endpoint를 호출</u>하여 클라이언트에서 속성값을 사용할 수 있다.

## OpenID Connect vs. OAuth 2.0
**OpenID Connect**은 OAuth 2.0의 확장 인증 프로토콜로, <u>인증에 초점을 맞춘다</u>.
**OAuth 2.0**은 인증 프레임워크로, 데이터에 대한 <u>액세스 권한 부여에 초점을 맞춘다<u>.

---
#### Reference
- [SAML 2.0 기반 SSO](https://developers.worksmobile.com/kr/document/2001070201?lang=ko)
- [SAML assertion](https://jumpcloud.com/blog/what-is-saml-assertion)
- https://boomkim.github.io/2018/07/11/rough-draft-of-saml/
- https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithSAML.html
- [브라우저에서 SAML 응답 확인](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_saml_view-saml-response.html)
- [OpenID Connect(OIDC) vs. SAML](https://gluu.org/oauth-vs-saml-vs-openid-connect)
- [OAuth 2.0과 OpenID Connect 정리](https://velog.io/@jakeseo_me/Oauth-2.0%EA%B3%BC-OpenID-Connect-%ED%94%84%EB%A1%9C%ED%86%A0%EC%BD%9C-%EC%A0%95%EB%A6%AC)
- [편의성을 높인 ID 인증 관리: OIDC가 주목 받는 이유](https://s-core.co.kr/insight/view/%ED%8E%B8%EC%9D%98%EC%84%B1%EC%9D%84-%EB%86%92%EC%9D%B8-id-%EC%9D%B8%EC%A6%9D-%EA%B4%80%EB%A6%AC-oidc%EA%B0%80-%EC%A3%BC%EB%AA%A9-%EB%B0%9B%EB%8A%94-%EC%9D%B4%EC%9C%A0/)