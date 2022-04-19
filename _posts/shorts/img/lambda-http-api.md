## Lambda HTTP API( API Gateway ) to send S3 presigned url

S3 object에 접근하기 위해서 Lambda에 연동된 IAM role에 `S3ReadOnlyAccess`을 추가해야 한다.

[Creating S3 presigned URLs using Python boto3](https://www.middlewareinventory.com/blog/s3-presigned-urls-boto3-aws-lambda/)


lambda hander 함수에 오류가 없어도 API Gateway와 연결하면 리턴값이 맞게 설정되지 않으면 Internal Server Error가 발생한다.

API Gateway가 받아들일 수 있는 형태(json)로 반환해야 한다. 

```python
def respond(msg, status=200):
    return {
        'statusCode': str(status),
        'body': msg,
        'headers': {},
    }

def lambda_handler(event, context):        
    return respond("hello world", status=200)
```

[Lambda로 Proxy 생성하기](https://bablabs.tistory.com/39)