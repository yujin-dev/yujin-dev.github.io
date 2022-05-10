## s3 버킷 간에 object 복사

### [Amazon S3 버킷 간 객체 복사](https://aws.amazon.com/ko/premiumsupport/knowledge-center/move-objects-s3-bucket/)

```bash
aws s3 sync s3://DOC-EXAMPLE-BUCKET-SOURCE s3://DOC-EXAMPLE-BUCKET-TARGET
```
`sync` 는 CopyObject API를 사용하여 S3 버킷 간에 객체를 복사하는 명령어이다. 소스 vs. 대상 버킷을 나열하여 대상 버킷에 없는 object를 식별하여 복사한다. 또한 마지막으로 수정한 날짜가 대상 버킷의 객체와 다른 객체를 식별한다. **기본적으로 객체 메타데이터를 보존한다**.

원본 버킷에 액세스 제어 목록(ACL)이 활성화되어 있으면 ACL이 대상 버킷으로 복사되지 않는다. 대상 버킷에서 ACL의 활성화 여부에 관계없이 마찬가지이다.

### 실행 예시 출력
aws s3 동기화를 실행하다가 중간에 Stop 후 다시 실행하면 겹치지 않게 로드된다.

```console
upload: source_dir/DATA010215.gz to s3://{s3-bucket}/DATA010215.gz         
upload: source_dir/DATA010218.gz to s3://{s3-bucket}/DATA010218.gz      
upload: source_dir/DATA010318.gz to s3://{s3-bucket}/DATA010318.gz       
upload: source_dir/DATA010220.gz to s3://{s3-bucket}/DATA010220.gz       
upload: source_dir/DATA010219.gz to s3://{s3-bucket}/DATA010219.gz       
upload: source_dir/DATA010317.gz to s3://{s3-bucket}/DATA010317.gz       
upload: source_dir/DATA010418.gz to s3://{s3-bucket}/DATA010418.gz       
upload: source_dir/DATA010319.gz to s3://{s3-bucket}/DATA010319.gz       
upload: source_dir/DATA010320.gz to s3://{s3-bucket}/DATA010320.gz       
upload: source_dir/DATA010417.gz to s3://{s3-bucket}/DATA010417.gz       
Completed 43.2 GiB/~59.7 GiB (10.6 MiB/s) with ~5 file(s) remaining (calculating...)

---- # stop 이후에 재실행
upload: source/DATA010416.gz to s3://{s3-bucket}/DATA010416.gz         
Completed 10.6 GiB/~30.9 GiB (10.7 MiB/s) with ~6 file(s) remaining (calculating...)
```

## AWS S3 storage class

- **S3 Intelligent-Tiering :** S3 스토리지 클래스에는 알 수 없거나 액세스 패턴이 변경되는 데이터에 대한 자동 비용 절감을 위한 스토리지
- **S3 Standard :** 자주 액세스하는 데이터를 위한 스토리지 클래스
- **S3 Standard-Infrequent Access(S3 Standard-IA)** , **S3 One Zone-Infrequent Access(S3 One Zone-IA) :** 자주 액세스하지 않는 데이터를 위한  스토리지 클래스
- **S3 Glacier Instant Retrieval :** 즉각적인 액세스가 필요한 아카이브 데이터를 위한 스토리지 클래스
- **S3 Glacier Flexible Retrieval(이전 S3 Glacier) :** 즉각적인 액세스가 필요하지 않고 거의 액세스하지 않는 장기 데이터를 위한 스토리지 클래스
- **Amazon S3 Glacier Deep Archive(S3 Glacier Deep Archive) :** 클라우드에서 가장 저렴한 스토리지로 몇 시간 만에 검색 가능한 장기간 아카이브 및 디지털 보존을 위한 스토리지 클래스