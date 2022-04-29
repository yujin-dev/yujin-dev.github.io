# event trigger on Cloud Logging

## Eventarc Architecture

Eventarc 를 사용하면 기본 인프라를 구현, 맞춤설정 또는 유지관리할 필요 없이 Cloud Run 을 통해서 이벤트 기반 아키텍처를 빌드할 수 있다. Eventarc는 Cloud Run 의 하나의 기능으로 오해하기 쉬운데 실제적으로는 CloudEvent 를 지원하는 별도의 완전 관리형 솔루션형태로 내부적으로 보면 **Event Core 와 Transport Layer 로 구성**되어 현재 타겟으로 Cloud Run 을 지원하게 된다.

![Untitled](https://cloud.google.com/eventarc/docs/images/broker-subscriber.svg?hl=ko)

![](https://cloud.google.com/eventarc/docs/images/eventarc-new-arch.svg)

이벤트 기반 시스템에서는 Event Producers가 이벤트를 생성하고 Event Router(또는 브로커)에서 이벤트를 필터링한 다음 적절한 Event Consumers(또는 싱크)로 팬아웃한다.. 이벤트는 하나 이상의 일치하는 트리거에 의해 정의된 Consumer에게 전달된다.

- [Cloud 감사 로그 이벤트 수신](https://cloud.google.com/eventarc/docs/run/cal?hl=ko) 
- [Serverless 서비스인 Cloud Run 알아보기 5부 — Eventarc 를 통한 이벤트 받기](https://medium.com/google-cloud-apac/gcp-serverless-%EC%84%9C%EB%B9%84%EC%8A%A4%EC%9D%B8-cloud-run-%EC%95%8C%EC%95%84%EB%B3%B4%EA%B8%B0-5%EB%B6%80-eventarc-%EB%A5%BC-%ED%86%B5%ED%95%9C-%EC%9D%B4%EB%B2%A4%ED%8A%B8-%EB%B0%9B%EA%B8%B0-f0771b656c4f)

에 따라 Cloud Run에서 실행하여 발생하는 이벤트 소스를 확인하면 아래와 같다.

```bash
# print(content)
{'insertId': '-',
 'logName': 'projects/my_project/logs/cloudaudit.googleapis.com%2Fdata_access',
 'protoPayload': {...
                  'metadata': {'@type': 'type.googleapis.com/google.cloud.audit.BigQueryAuditMetadata',
                               'tableDataChange': {'insertedRowsCount': '1967',
                                                   ..
                                                   'reason': 'JOB'}},
                  'methodName': 'google.cloud.bigquery.v2.JobService.InsertJob',
                 ..
                  'resourceName': 'projects/my_project/datasets/my_dataset/tables/_staging_table',
                  'serviceData': {},
                  'serviceName': 'bigquery.googleapis.com',
                  'status': {}},
 'receiveTimestamp': '2022-04-21T05:01:26.227789045Z',
 'resource': {'labels': {'dataset_id': 'my_dataset',
                         'project_id': 'my_project'},
              'type': 'bigquery_dataset'},
 'severity': 'INFO',
 'timestamp': '2022-04-21T05:01:26.169705Z'}
```

### Cloud Run Not automatically update container image

[Continuous Deployment to Cloud Run Services based on a New Container Image.](https://medium.com/google-cloud/continuous-deployment-to-cloud-run-services-based-on-a-new-container-image-bccd776b7357)

Cloud Run에 배포한 컨테이너 이미지는 자동으로 적용되지 않는 것으로 보인다.