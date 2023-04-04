---
layout: post
title: Pulumi Bug Report
categories: [IaC]
date: 2022-07-08
---

## `pulumi up`을 실행하는데 protobuf 관련 오류
```console
    Traceback (most recent call last):
      File "/home/leeyujin/.pulumi/bin/pulumi-language-python-exec", line 14, in <module>
        import pulumi
      ...  
	  _message.Message._CheckCalledFromGeneratedFile()
    TypeError: Descriptors cannot not be created directly.
    If this call came from a _pb2.py file, your generated code is out of date and must be regenerated with protoc >= 3.19.0.
```

- 원인 : protocol buffer 버전 문제인 것으로 추정된다.  
- 해결 : 다음 2가지가 있다.
  ```
    1. Downgrade the protobuf package to 3.20.x or lower.
    2. Set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python (but this will use pure-Python parsing and will be much slower).
  ```
  `PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python`으로 설정하여 해결

## 이전에 업데이트하던 작업이 pending되어 이후 업데이트와 충돌
```console
error: the current deployment has 1 resource(s) with pending operations:
  * urn:pulumi:dev::kubernetes:core/v1:Service:, interrupted while updating

These resources are in an unknown state because the Pulumi CLI was interrupted while
waiting for changes to these resources to complete. You should confirm whether or not the
operations listed completed successfully by checking the state of the appropriate provider.
For example, if you are using AWS, you can confirm using the AWS Console.

Once you have confirmed the status of the interrupted operations, you can repair your stack
using 'pulumi stack export' to export your stack to a file. For each operation that succeeded,
remove that operation from the "pending_operations" section of the file. Once this is complete,
use 'pulumi stack import' to import the repaired stack.

refusing to proceed
```
- 원인 : 이전에 업데이트 하는 중에 인터럽트가 발생하여 리소스 상태가 완료되지 않았다.
- 해결
  - `pulumi stack export --file {file_name}`로 stack 상태를 출력하여 `pending_operations`에 해당하는 값을 삭제하여 파일을 수정한다. 
  - 수정이 완료된  파일은 `pulumi stack import --file {file_name}`로 직접 상태를 업데이트한다.

## `image_pull_secret` 관련 오류
```
error: resource ..deployment was not successfully created by the Kubernetes API server : Deployment in version "v1" cannot be handled as a Deployment: v1.Deployment.Spec: v1.DeploymentSpec.Template: v1.PodTemplateSpec.Spec: v1.PodSpec.ImagePullSecrets: []v1.LocalObjectReference: decode slice: expect [ or n, but found ", error found in #10 byte of ...|Secrets":"|..., bigger context ...|"server","protocol":"TCP"}]}],"imagePullSecrets":"","serviceAccountName":"|...
```
- 원인 : string으로 값을 입력
- 해결 : `LocalObjectReference`을 사용

## `stderr: error: failed to decrypt encrypted configuration value 'snowflake:password': bad value`
```
This can occur when a secret is copied from one stack to another. Encryption of secrets is done per-stack and
it is not possible to share an encrypted configuration value across stacks.
```
- github action에서 설정해놓은 `PULUMI_CONFIG_PASSPHRASE`에 맞춰 pulumi config를 실행하지 않음
- 해결
  - `PULUMI_CONFIG_PASSPHRASE`를 github action에서 설정한 것과 동일하게 세팅한다.
  - `pulumi config set snowflake:password --secret {password}`를 실행하여 Pulumi.dev.yaml을 업데이트해준다.
