data fusion replication( existing table reload )

![Untitled](Untitled.png)

![Untitled](Untitled%201.png)

![Untitled](Untitled%202.png)

![Untitled](Untitled%203.png)

- Raw data source에서 테이블 전체를 복제하여 로드한다. 로드된 데이터는 GCS에 임시로 JSONL파일로 저장된다. 파일은 빅쿼리에 로드된 후 삭제되는 것으로 파악된다. 위의 경우 4번에 걸쳐 로드 작업이 이루어진 것으로 보인다. throughput이 1GB/1h으로 미리 설정되어 있는데
- 기존 테이블의 `_sequence_num` 가장 큰 값과 임시 저장된 raw data 테이블의 `_sequence_num` 과 비교하여 기존의 Max값 이상의 데이터를 MERGE하여 업데이트한다.
    
    ```bash
    MERGE `compustat_raw.spind_dly` as T
    USING (SELECT A.* FROM
    (SELECT * FROM `compustat_raw._staging_spind_dly` WHERE _batch_id = 1651460467442 AND _sequence_num > 14710639) as A
    LEFT OUTER JOIN
    (SELECT * FROM `compustat_raw._staging_spind_dly` WHERE _batch_id = 1651460467442 AND _sequence_num > 14710639) as B
    ON A.`gvkey` = B.`_before_gvkey` AND A.`datadate` = B.`_before_datadate` AND A._sequence_num < B._sequence_num
    WHERE B.`_before_gvkey` IS NULL AND B.`_before_datadate` IS NULL) as D
    ON T.`gvkey` = D.`_before_gvkey` AND T.`datadate` = D.`_before_datadate`
    WHEN MATCHED AND D._op = "DELETE" THEN
      DELETE
    WHEN MATCHED AND D._op IN ("INSERT", "UPDATE") THEN
      UPDATE SET `gvkey` = D.`gvkey`, `datadate` = D.`datadate`, `spihi` = D.`spihi`, `spilo` = D.`spilo`, `spinumn` = D.`spinumn`, `spinumo` = D.`spinumo`, `spiprc` = D.`spiprc`, `_sequence_num` = D.`_sequence_num`, _is_deleted = null
    WHEN NOT MATCHED AND D._op IN ("INSERT", "UPDATE") THEN
      INSERT (`gvkey`, `datadate`, `spihi`, `spilo`, `spinumn`, `spinumo`, `spiprc`, `_sequence_num`) VALUES (`gvkey`, `datadate`, `spihi`, `spilo`, `spinumn`, `spinumo`, `spiprc`, `_sequence_num`)
    ```
    

### gcp compute engine

- [사전 정의된 머신 유형:](https://cloud.google.com/compute/docs/machine-types?hl=ko) 사전 빌드되어 즉시 사용 가능한 구성으로 빠르게 실행할 수 있습니다.
- [커스텀 머신 유형](https://cloud.google.com/custom-machine-types?hl=ko): 비용의 균형을 맞추며 최적의 vCPU와 메모리 용량을 갖춘 VM을 만들 수 있습니다.
- [스팟 머신:](https://cloud.google.com/spot-vms?hl=ko)컴퓨팅 비용을 최대 91% 줄일 수 있습니다.
- [컨피덴셜 컴퓨팅](https://cloud.google.com/confidential-computing?hl=ko): 가장 민감한 정보를 처리 중에도 암호화할 수 있습니다.
- [적정 크기 권장:](https://cloud.google.com/compute/docs/instances/apply-sizing-recommendations-for-instances?hl=ko#how_sizing_recommendations_work) 자동 추천 기능을 통해 리소스 사용률을 최적화할 수 있습니다.

### IAM의 정책 및 권한

policy는 자격 증명(user, user group 또는 role)이나 리소스와 연결될 때 해당 권한을 정의하는 AWS의 객체입니다. AWS는 IAM 보안 주체인 user나 role에서 요청을 보낼 때 policy를 평가하여 허용하거나 거부할지 결정합니다. 대부분 AWS에서 JSON 문서로 저장된다.

Policy

- **[Identity-based policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_id-based) :** managed 및 inline 정책을 identity( user나 group 또는 role )에 연결한다.
- **[Resource-based policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_resource-based)** : inline 정책을 특정 resource에 연결한다.
- **[Permissions boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_bound) :** managed 정책을 IAM 엔터티(사용자 또는 역할)에 대한 권한 경계로 사용한다.
- **[Organizations SCP](https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/access_policies.html#policies_scp)** : AWS Organizations 서비스 제어 정책(SCP)을 사용하여 조직 또는 조직 단위(OU)의 계정 멤버에 대한 최대 권한을 정의한다.
- **[Access control lists (ACLs)](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_acl) :** ACL을 사용하여 ACL이 연결된 리소스에 액세스할 수 있는 다른 계정의 보안 주체를 제어한다. 다만 JSON 정책 문서 구조를 사용하지 않은 유일한 정책 유형입니다
- **[Session policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session)**

A role is an IAM identity that you can create in your account that has specific permissions. An IAM role has some similarities to an IAM user. Roles and users are both AWS identities with permissions policies that determine what the identity can and cannot do in AWS. However, instead of being uniquely associated with one person, a role can be assumed by anyone who needs it. A role does not have standard long-term credentials such as a password or access keys associated with it. Instead, when you assume a role, it provides you with temporary security credentials for your role session.

**ARN**

Amazon 리소스 이름(ARN)은 AWS 리소스를 고유하게 식별합니다.

```bash
arn:partition:service:region:account-id:resource-id
arn:partition:service:region:account-id:resource-type/resource-id
arn:partition:service:region:account-id:resource-type:resource-id
```

partition : aws  region group ( aws )

service : iam, ..

remote server( S3 bucket ) to S3 bucket - DataSync 

![Untitled](Untitled%204.png)

- agent : 자체 관리 대상 위치에서 데이터를 복제하는데 사용되는 VM
- location : S3, HDFS, NFS, EFS 등 대상 위치
- task : DataSync 전송

agent 배포

- VMware
- KVM
- Hyper-V

KVM vs. Hyper-V

Microsoft's Hyper-V and Linux's KVM are capable, enterprise-class **hypervisors that can [host VMs](https://searchservervirtualization.techtarget.com/definition/host-virtual-machine-host-VM)** and scale to the largest of workloads.

The main difference of Hyper-V vs. KVM is that **Hyper-V** is from Microsoft and runs on Windows, while **KVM** is an [open source hypervisor](https://searchservervirtualization.techtarget.com/answer/Open-source-hypervisor-technical-support-update-considerations) built into Linux.

KVM vs. VMware

하이퍼바이저는 [가상화](https://www.redhat.com/ko/topics/virtualization) 플랫폼의 기반을 제공하며, 전통적인 벤더에서부터 오픈소스 벤더에 이르는 다양한 벤더에서 선택할 수 있습니다. **VMware**는 가상화 솔루션의 선도기업으로 ESXi 하이퍼바이저와 vSphere 가상화 플랫폼을 제공합니다. **KVM**(커널 기반 가상 시스템)은 [오픈소스](https://www.redhat.com/ko/about/open-source) 옵션으로 [Linux®](https://www.redhat.com/ko/topics/linux)에 포함되어 있습니다.

**AWS Transfer for SFTP( Transfer Family )**

SFTP 프로토콜로 파일을 SFTP 서버를 관리하는 대신 AWS S3에 저장하는 서비스이다.

SFTP 클라이언트는 서버의 ID를 DNS이름 + IP주소 + SSH 호스트키로 구성된다.

기존 SFTP서버를 이식하려면

- DNS 이식 : AWS SFTP 서버와 새 서버의 엔드포인트를 가리키는 DNS CNAME 별칭을 생성한다( Route 53 사용 ). 기존 온프레미스 서버에서 credential를 가져온 후 홈 디렉토리로 미러링하도록 폴더를 설정한다.
- IP주소 이식 : SFTP 사용자가 화이트리스트로 관리되는 방화벽 내에 있는 경우 DNS 이식성이 충분하지 않을 수 있다.
- 호스트 키 이식 : SFTP 클라이언트는 서버에 처음 연결할 때 public key를 사용한다.

[Lift and Shift migration of SFTP servers to AWS | Amazon Web Services](https://aws.amazon.com/ko/blogs/storage/lift-and-shift-migration-of-sftp-servers-to-aws/)

**AWS SFTP를 사용하여 온프레미스에서 Amazon S3 로 소규모 데이터 세트 마이그레이션**

- 용도 : 온프레미스 플랫 파일 / 데이터베이스 덤프

![Untitled](Untitled%205.png)

- AWS SFTP : SFTP를 사용하여 S3에서 바로 파일을 전송
- AWS Direct Connect : 온프레미스 데이터 센터에서 AWS까지 전용 네트워크 연결을 설정한다. 표준 이더넷 광섬유 케이블을 통해 내부 네트워크를 통해 AWS Direct Connect에 연결할 수 있다. 케이블의 한쪽은 사용자의 라우터에 연결하고 다른 쪽은 AWS Direct Connect 라우터에 연결하는 방식이다.
- VPC 엔드포인트

전체 과정 예시

[AWS Transfer로 Serverless SFTP 구현](https://techblog.kr/2021/05/10/serverless-sftp/)

**FSx for Lustre :** 파일 시스템을 S3 버킷에 링크

Amazon FSx for Lustre 파일 시스템을 Amazon S3의 데이터 리포지토리에 연결할 수 있다.

파일 시스템의 디렉토리와 S3 버킷간의 링크는 DRA( Data Repository Association )이라 한다.파일 시스템에 대해 한 번에 하나의 요청만 작업 가능하다. 

- File system path : Data repository path( S3 버킷 경로 )는 1:1 매핑으로 설정된다.
- FSx 파일 시스템을 마운트하는 어플리케이션에서 S3 버킷에 저장된 객체에 액세스 가능하다. 자동 가져오기나 데이터 저장소 가져오기를 통해 연결된 데이터 저장소에서 해당 파일 시스템으로 파일을 가져올 수 있다.
- 여러 S3 버킷으로 완전한 양방향 동기화 구현 : S3 버킷에 대한 빠른 POSIX 파일 시스템 액세스가 워크로드에 필요한 경우 FSx for Lustre를 사용하여 S3 버킷을 파일 시스템에 연결하고 파일 시스템과 S3 간에 양방향으로 데이터를 동기화할 수 있다.
    - 자동 내보내기 정책 : FSx for Lustre 파일 시스템의 파일에 대해 S3의 데이터 리포지토리로 내보내기가 자동으로 수행된다. 또한 S3에서 삭제된 객체가 FSx for Lustre 파일 시스템에서 삭제되고 반대도 가능하다.
    - 여러 S3 버킷과 동기화되는데 S3 버킷 로그는 `/fsx/logs`로 매핑되고 다른 financial_data 버킷은 `/fsx/finance`에 매핑될 수 있다.
    - 여러 S3 버킷이나 prefix를 사용하여 datalake에 대한 엑세스를 구성 및 관리하고 S3 버킷의 파일에 엑세스 가능하다.
    
    [Amazon FSx for Lustre와 Amazon S3 통합 기능 출시 | Amazon Web Services](https://aws.amazon.com/ko/blogs/korea/enhanced-amazon-s3-integration-for-amazon-fsx-for-lustre/)
    

**Lustre** (file system)

병렬 분산 파일 시스템의 일종으로 large-scale 클러스터 컴퓨팅에서 주로 사용된다. 

workflow

> 자동 내보내기 및 여러 리포지토리는 미국 동부(버지니아 북부), 미국 동부(오하이오), 미국 서부(오레곤), 캐나다(중부), 아시아 태평양(도쿄), 유럽(프랑크푸르트) 및 유럽(아일랜드)의 Persistent 2 파일 시스템에서만 사용할 수 있습니다. S3에서 삭제되거나 이동된 객체를 지원하는 자동 가져오기는 FSx for Lustre를 사용할 수 있는 모든 리전에서 2020년 7월 23일 이후에 생성된 파일 시스템에 대해 사용할 수 있습니다.
> 
- 동일한 VPC 서브넷 내에서 FSx 파일 시스템과 EC2 인스턴스를 생성한다.
- EC2 인스턴스에 탑재 : `sudo mount -t lustre -o noatime,flock *file_system_dns_name*@tcp:/*mountname* /fsx`

s3fs-fuse, goofys와 같은 s3 bucket을 파일 시스템으로 mount하는 오픈 소스가 있으나 속도나 안정성 측면에서 있을 수.. 있으므로 pass

**AWS Database Migration service**

RDB, Datawarehouse, NoSQL 등 데이터 저장소를 migration할 수 있는 서비스이다. 

한 번 수행하면 지속적인 변경 사항을 복제하여 [source](https://docs.aws.amazon.com/ko_kr/dms/latest/userguide/CHAP_Introduction.Sources.html)와 [target](https://docs.aws.amazon.com/ko_kr/dms/latest/userguide/CHAP_Introduction.Targets.html)을 동기화할 수 있다.

![Untitled](Untitled%206.png)

**s3 버킷 간에 object 복사**

```bash
aws s3 sync s3://DOC-EXAMPLE-BUCKET-SOURCE s3://DOC-EXAMPLE-BUCKET-TARGET
```

`sync` 는 CopyObject API를 사용하여 S3 버킷 간에 객체를 복사하는 명령어이다. 소스 vs. 대상 버킷을 나열하여 대상 버킷에 없는 object를 식별하여 복사한다. 또한 마지막으로 수정한 날짜가 대상 버킷의 객체와 다른 객체를 식별한다. **기본적으로 객체 메타데이터를 보존한다**.

원본 버킷에 액세스 제어 목록(ACL)이 활성화되어 있으면 ACL이 대상 버킷으로 복사되지 않는다. 대상 버킷에서 ACL의 활성화 여부에 관계없이 마찬가지.

[Amazon S3 버킷 간 객체 복사](https://aws.amazon.com/ko/premiumsupport/knowledge-center/move-objects-s3-bucket/)

**AWS S3 storage class**

- **S3 Intelligent-Tiering :** S3 스토리지 클래스에는 알 수 없거나 액세스 패턴이 변경되는 데이터에 대한 자동 비용 절감을 위한 스토리지
- **S3 Standard :** 자주 액세스하는 데이터를 위한 스토리지 클래스
- **S3 Standard-Infrequent Access(S3 Standard-IA)** , **S3 One Zone-Infrequent Access(S3 One Zone-IA) :** 자주 액세스하지 않는 데이터를 위한  스토리지 클래스
- **S3 Glacier Instant Retrieval :** 즉각적인 액세스가 필요한 아카이브 데이터를 위한 스토리지 클래스
- **S3 Glacier Flexible Retrieval(이전 S3 Glacier) :** 즉각적인 액세스가 필요하지 않고 거의 액세스하지 않는 장기 데이터를 위한 스토리지 클래스
- **Amazon S3 Glacier Deep Archive(S3 Glacier Deep Archive) :** 클라우드에서 가장 저렴한 스토리지로 몇 시간 만에 검색 가능한 장기간 아카이브 및 디지털 보존을 위한 스토리지 클래스