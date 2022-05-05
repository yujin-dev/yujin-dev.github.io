### s3 버킷 간에 object 복사

```bash
aws s3 sync s3://DOC-EXAMPLE-BUCKET-SOURCE s3://DOC-EXAMPLE-BUCKET-TARGET
```

`sync` 는 CopyObject API를 사용하여 S3 버킷 간에 객체를 복사하는 명령어이다. 소스 vs. 대상 버킷을 나열하여 대상 버킷에 없는 object를 식별하여 복사한다. 또한 마지막으로 수정한 날짜가 대상 버킷의 객체와 다른 객체를 식별한다. **기본적으로 객체 메타데이터를 보존한다**.

원본 버킷에 액세스 제어 목록(ACL)이 활성화되어 있으면 ACL이 대상 버킷으로 복사되지 않는다. 대상 버킷에서 ACL의 활성화 여부에 관계없이 마찬가지이다.

[Amazon S3 버킷 간 객체 복사](https://aws.amazon.com/ko/premiumsupport/knowledge-center/move-objects-s3-bucket/)

### AWS S3 storage class

- **S3 Intelligent-Tiering :** S3 스토리지 클래스에는 알 수 없거나 액세스 패턴이 변경되는 데이터에 대한 자동 비용 절감을 위한 스토리지
- **S3 Standard :** 자주 액세스하는 데이터를 위한 스토리지 클래스
- **S3 Standard-Infrequent Access(S3 Standard-IA)** , **S3 One Zone-Infrequent Access(S3 One Zone-IA) :** 자주 액세스하지 않는 데이터를 위한  스토리지 클래스
- **S3 Glacier Instant Retrieval :** 즉각적인 액세스가 필요한 아카이브 데이터를 위한 스토리지 클래스
- **S3 Glacier Flexible Retrieval(이전 S3 Glacier) :** 즉각적인 액세스가 필요하지 않고 거의 액세스하지 않는 장기 데이터를 위한 스토리지 클래스
- **Amazon S3 Glacier Deep Archive(S3 Glacier Deep Archive) :** 클라우드에서 가장 저렴한 스토리지로 몇 시간 만에 검색 가능한 장기간 아카이브 및 디지털 보존을 위한 스토리지 클래스