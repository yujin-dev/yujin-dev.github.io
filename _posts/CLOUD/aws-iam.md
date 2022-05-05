### gcp compute engine

- [사전 정의된 머신 유형:](https://cloud.google.com/compute/docs/machine-types?hl=ko) 사전 빌드되어 즉시 사용 가능한 구성으로 빠르게 실행할 수 있습니다.
- [커스텀 머신 유형](https://cloud.google.com/custom-machine-types?hl=ko): 비용의 균형을 맞추며 최적의 vCPU와 메모리 용량을 갖춘 VM을 만들 수 있습니다.
- [스팟 머신:](https://cloud.google.com/spot-vms?hl=ko)컴퓨팅 비용을 최대 91% 줄일 수 있습니다.
- [컨피덴셜 컴퓨팅](https://cloud.google.com/confidential-computing?hl=ko): 가장 민감한 정보를 처리 중에도 암호화할 수 있습니다.
- [적정 크기 권장:](https://cloud.google.com/compute/docs/instances/apply-sizing-recommendations-for-instances?hl=ko#how_sizing_recommendations_work) 자동 추천 기능을 통해 리소스 사용률을 최적화할 수 있습니다.

### IAM의 정책 및 권한

- policy는 자격 증명(user, user group 또는 role)이나 리소스와 연결될 때 해당 권한을 정의하는 AWS의 객체입니다. AWS는 IAM 보안 주체인 user나 role에서 요청을 보낼 때 policy를 평가하여 허용하거나 거부할지 결정합니다. 대부분 AWS에서 JSON 문서로 저장된다.

**Policy**

- **[Identity-based policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_id-based) :** managed 및 inline 정책을 identity( user나 group 또는 role )에 연결한다.
- **[Resource-based policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_resource-based)** : inline 정책을 특정 resource에 연결한다.
- **[Permissions boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_bound) :** managed 정책을 IAM 엔터티(사용자 또는 역할)에 대한 권한 경계로 사용한다.
- **[Organizations SCP](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/access_policies.html#policies_scp)** : AWS Organizations 서비스 제어 정책(SCP)을 사용하여 조직 또는 조직 단위(OU)의 계정 멤버에 대한 최대 권한을 정의한다.
- **[Access control lists (ACLs)](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_acl) :** ACL을 사용하여 ACL이 연결된 리소스에 액세스할 수 있는 다른 계정의 보안 주체를 제어한다. 다만 JSON 정책 문서 구조를 사용하지 않은 유일한 정책 유형입니다
- **[Session policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session)**

**Role**

A role is an IAM identity that you can create in your account that has specific permissions. An IAM role has some similarities to an IAM user. Roles and users are both AWS identities with permissions policies that determine what the identity can and cannot do in AWS. However, instead of being uniquely associated with one person, a role can be assumed by anyone who needs it. A role does not have standard long-term credentials such as a password or access keys associated with it. Instead, when you assume a role, it provides you with temporary security credentials for your role session.

**ARN**

Amazon 리소스 이름(ARN)은 AWS 리소스를 고유하게 식별합니다.

```bash
arn:partition:service:region:account-id:resource-id
arn:partition:service:region:account-id:resource-type/resource-id
arn:partition:service:region:account-id:resource-type:resource-id
```

- partition : aws  region group ( aws )
- service : iam, ..
