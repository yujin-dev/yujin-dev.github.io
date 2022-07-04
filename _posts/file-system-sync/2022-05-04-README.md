---
title: "File System Synchronization"
---

## *Lustre*?
병렬 분산 파일 시스템의 일종으로, large-scale 클러스터 컴퓨팅에서 주로 사용된다.

AWS FSx for Lustre는 고성능 파일 시스템에 구축된 높은 처리량, IOPS를 제공하는 공유 스토리지이다. S3 버킷에 연결하여 데이터를 파일 시스템에서 관리할 수 있다.
    
> 출처 : [Amazon FSx for Lustre와 Amazon S3 통합 기능 출시 | Amazon Web Services](https://aws.amazon.com/ko/blogs/korea/enhanced-amazon-s3-integration-for-amazon-fsx-for-lustre/)

Amazon FSx for Lustre 파일 시스템을 Amazon S3의 데이터 리포지토리에 연결할 수 있다.

파일 시스템의 디렉토리와 S3 버킷간의 링크는 DRA( Data Repository Association )이라 한다. 파일 시스템에 대해 한 번에 하나의 요청만 작업 가능하다. 

- File system path : Data repository path( S3 버킷 경로 )는 **1:1 매핑**으로 설정된다.
- FSx 파일 시스템을 마운트하는 어플리케이션에서 S3 버킷에 저장된 객체에 액세스 가능하다. 자동 가져오기나 데이터 저장소 가져오기를 통해 연결된 데이터 저장소에서 해당 **파일 시스템으로 파일을 가져올 수 있다**.
- 여러 S3 버킷으로 완전한 **양방향 동기화** 구현 : S3 버킷에 대한 빠른 POSIX 파일 시스템 액세스가 워크로드에 필요한 경우 FSx for Lustre를 사용하여 S3 버킷을 파일 시스템에 연결하고 파일 시스템과 S3 간에 양방향으로 데이터를 동기화할 수 있다.
    - 자동 내보내기 정책 : FSx for Lustre 파일 시스템의 파일에 대해 S3의 데이터 리포지토리로 내보내기가 자동으로 수행된다. 또한 S3에서 삭제된 객체가 FSx for Lustre 파일 시스템에서 삭제되고 반대도 가능하다.
    - 여러 S3 버킷과 동기화되는데 S3 버킷 로그는 `/fsx/logs`로 매핑되고 다른 financial_data 버킷은 `/fsx/finance`에 매핑될 수 있다.
    - 여러 S3 버킷이나 prefix를 사용하여 datalake에 대한 엑세스를 구성 및 관리하고 S3 버킷의 파일에 엑세스 가능하다.

requirements 및 workflow는 기본적으로 아래와 같다.
- 자동 내보내기 및 여러 리포지토리는 미국 동부(버지니아 북부), 미국 동부(오하이오), 미국 서부(오레곤), 캐나다(중부), 아시아 태평양(도쿄), 유럽(프랑크푸르트) 및 유럽(아일랜드)의 Persistent 2 파일 시스템에서만 사용할 수 있다.
- 동일한 VPC 서브넷 내에서 FSx 파일 시스템과 EC2 인스턴스를 생성한다.
- EC2 인스턴스에 탑재 : `sudo mount -t lustre -o noatime,flock *file_system_dns_name*@tcp:/*mountname* /fsx`

### Setup
인프라 셋업은 pulumi를 적용하여 진행하였다.

- 사용하려는 S3 버킷을 동기화하여 FSx lustre filesystem 생성한다.
  - 아래와 같이 Data Repository를 S3 버킷과 연동하려면 deployment_type 이 PERSISTENT_2 으로 설정하여야 하는데 seoul region에서는 PERSISTENT_1 을 사용해야 하므로 us region에서 진행한다.  
  - *Per unit storage throughput represents the megabytes per second of read or write throughput per 1 tebibyte of storage provisioned. File system throughput capacity is equal to Storage capacity (TiB) * PerUnitStorageThroughput (MB/s/TiB). This option is only valid for `PERSISTENT_1` and `PERSISTENT_2` deployment types.*  
    - `PERSISTENT_1` SSD storage: 50, 100, 200.
    - `PERSISTENT_1` HDD storage: 12, 40.
    - `PERSISTENT_2` SSD storage: 125, 250, 500, 1000.  

    ![Untitled](Untitled43.png)  
    ![Untitled](Untitled44.png)

  - storage_type SSD를 적용하면( PERSISTENT_2에서는 SSD만 허용 ) 처리량은 [125, 250, 500, 1000] 중 하나로 선택해야 한다. storage_capacity 는 1200GB부터 시작하여 2400GB씩 증가시킬 수 있다.
  - Data Repository에서 연동하려면 S3 버킷을 설정한다.

#### pulumi code
```python

class Migration:
  ...

  fsx = aws.fsx.LustreFileSystem(
                          resource_name = self.name+"-fsx",
                          deployment_type="PERSISTENT_2", # ["SCRATCH_1", "SCRATCH_2", "PERSISTENT_1","PERSISTENT_2"]
                          storage_type="SSD", # ["SSD", "HDD"] #HDD is only supported on PERSISTENT_1 deployment types
                          per_unit_storage_throughput = 125, # (MB/s/TiB) PERSISTENT_1 + SSD: [50, 100, 200], PERSISTENT_2 + SDD: [125, 250, 500, 1000]
                          storage_capacity = 1200, # GiB ( 10 TiB to be 10800 GiB ) start from 1200, increments of 2400
                          data_compression_type = None,
                          security_group_ids = [self.security_group.id],
                          subnet_ids = self.subnet.id,
                          tags = {
                                  "Name": self.name
                          }
                  )
  
  aws.fsx.DataRepositoryAssociation(
          resource_name = self.name+"-association",
          file_system_id=self.fsx.id,
          data_repository_path=f"s3://{self.bucket_name}",
          file_system_path="/mount",
          s3 = aws.fsx.DataRepositoryAssociationS3Args(
                  auto_export_policy=aws.fsx.DataRepositoryAssociationS3AutoExportPolicyArgs(
                          events=["NEW", "CHANGED", "DELETED"],
                  ),
                  auto_import_policy=aws.fsx.DataRepositoryAssociationS3AutoImportPolicyArgs(
                          events=["NEW", "CHANGED", "DELETED"],
                  )
          ),
          tags = {
          "Name": self.name
          }
  )
```
  전체적인 인프라 셋업은 아래와 같이 생성된다.(resource의 dependency에 따라 차례대로 생성)
  ```bash
  $ pulumi up
----------------
  Type                                  Name                          Plan       Info
  +   pulumi:pulumi:Stack                   datalake_storage-sync-s3      create     1 message
  +   ├─ aws:s3:Bucket                      project-bucket       create     
  +   ├─ aws:ec2:Vpc                        us-east-1-default-vpc         create     
  +   ├─ aws:ec2:Subnet                     us-east-1-default-subnet      create     
  +   ├─ aws:ec2:SecurityGroup              us-east-1-default-sg          create     
  +   ├─ aws:fsx:LustreFileSystem           project-fsx          create     
  +   ├─ aws:ec2:Instance                   project-ec2          create     
  +   └─ aws:fsx:DataRepositoryAssociation  project-association  create

  ... # subnet 생성이 실패하면서 의존성이 있는 ec2나 fsx가 생성되지 않았다.
  Type                      Name                      Status                  Info
  +   pulumi:pulumi:Stack       datalake_storage-sync-s3  **creating failed**     1 error; 1 message
  +   ├─ aws:s3:Bucket          project-bucket   created                 
  +   ├─ aws:ec2:Vpc            us-east-1-default-vpc     created                 
  +   ├─ aws:ec2:Subnet         us-east-1-default-subnet  **creating failed**     1 error
  +   └─ aws:ec2:SecurityGroup  us-east-1-default-sg      created
  ```

- FSx 파일 시스템을 마운트하고  파일 복제를 진행할 EC2 인스턴스를 하나 생성할 때 lustre client를 설치한다: `amazon-linux-extras install -y lustre2.10`
- 인스턴스에 접속해 빈 폴더를 생성하고 FSx for lustre filesystem을 마운트한다.   

        ```
        $ mkdir -p target 
        $ sudo mount -t lustre -o noatime,flock fs-xxxx.fsx.us-east-1.amazonaws.com@tcp:/pumev target
        ```
        
## DataSync 

![Untitled](Untitled%204.png)

- agent : 자체 관리 대상 위치에서 데이터를 복제하는데 사용되는 VM
  - VMware
  - KVM
  - Hyper-V
- location : S3, HDFS, NFS, EFS 등 대상 위치
- task : DataSync 전송

## AWS Transfer for SFTP( Transfer Family )

SFTP 프로토콜로 파일을 SFTP 서버를 관리하는 대신 AWS S3에 저장하는 서비스이다.  
SFTP 클라이언트는 서버의 ID를 DNS이름 + IP주소 + SSH 호스트키로 구성된다.

기존 SFTP서버를 이식하려면
- DNS 이식 : AWS SFTP 서버와 새 서버의 엔드포인트를 가리키는 DNS CNAME 별칭을 생성한다( Route 53 사용 ). 기존 온프레미스 서버에서 credential를 가져온 후 홈 디렉토리로 미러링하도록 폴더를 설정한다.
- IP주소 이식 : SFTP 사용자가 화이트리스트로 관리되는 방화벽 내에 있는 경우 DNS 이식성이 충분하지 않을 수 있다.
- 호스트 키 이식 : SFTP 클라이언트는 서버에 처음 연결할 때 public key를 사용한다.

> 출처 : [Lift and Shift migration of SFTP servers to AWS | Amazon Web Services](https://aws.amazon.com/ko/blogs/storage/lift-and-shift-migration-of-sftp-servers-to-aws/)

### AWS SFTP를 사용하여 온프레미스에서 Amazon S3 로 소규모 데이터 세트 마이그레이션

- 용도 : 온프레미스 플랫 파일 / 데이터베이스 덤프

![Untitled](Untitled%205.png)

- AWS SFTP : SFTP를 사용하여 S3에서 바로 파일을 전송
- AWS Direct Connect : 온프레미스 데이터 센터에서 AWS까지 전용 네트워크 연결을 설정한다. 표준 이더넷 광섬유 케이블을 통해 내부 네트워크를 통해 AWS Direct Connect에 연결할 수 있다. 케이블의 한쪽은 사용자의 라우터에 연결하고 다른 쪽은 AWS Direct Connect 라우터에 연결하는 방식이다.
- VPC 엔드포인트

> 참고: [AWS Transfer로 Serverless SFTP 구현](https://techblog.kr/2021/05/10/serverless-sftp/)


## fuse open source
s3fs-fuse, goofys와 같은 s3 bucket을 파일 시스템으로 mount하는 오픈 소스가 있으나 속도나 안정성 측면에서 있을 수.. 있으므로 pass

## AWS Database Migration service

RDB, Datawarehouse, NoSQL 등 데이터 저장소를 migration할 수 있는 서비스이다. 

한 번 수행하면 지속적인 변경 사항을 복제하여 [source](https://docs.aws.amazon.com/ko_kr/dms/latest/userguide/CHAP_Introduction.Sources.html)와 [target](https://docs.aws.amazon.com/ko_kr/dms/latest/userguide/CHAP_Introduction.Targets.html)을 동기화할 수 있다.

![Untitled](Untitled%206.png)

## 원격 동기화( `rsync` )

- 원격 시스템으로부터 파일을 효율적으로 복사하거나 동기화하는데 파일의 부가 정보도 복사 가능하다. `scp`보다 빠른데 `rsync`는  차이가 있는 파일만 복사하고 데이터를 압축해서 전송이 가능하기에 더 적은 대역폭을 사용한다.
- 파일의 크기와 수정 시간을 비교하여 전송할지 말지 결정하는데 누락되는 경우가 있을 수 있어 `--checksum` 옵션을 이용하면 비교 방법을 개선할 수 있다. 
- 파일을 고정 크기의 chunk로 나누어 checksum을 계산한다. checksum을 서로 계산하여 다른 부분의 chunk만 복사한다. 

> 출처 : [Rsync Blog](https://www.joinc.co.kr/w/Site/Tip/Rsync)

`rsync` 는 **타겟 폴더에 소스 파일들이 이미 존재하여 변경 사항을 복사할 때 큰 효율성이 보일 것으로 기대된다**. 또는 네트워크 대역폭에 제한이 있을 때 압축해서 복사하는 장점이 있다 하지만, 새로운 파일을 전체 복사하는 경우에는 빠르게 진행될지는 모르겠다.