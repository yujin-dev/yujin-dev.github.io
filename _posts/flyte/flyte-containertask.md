---
title: "Flyte ContainerTask"
category: "flyte"
---

`ContainerTask`를 통해 flyte task를 등록하고 실행한다.

## flyte task 실행을 위한 docker image
flyte 전용 worker container image를 빌드한다.

```console
$ cd flyte-worker-docker
$ docker build . --tag flyte-worker:latest
```

해당 이미지를 기반으로 customize하여 task에 맞는 이미지를 생성할 수 있도록 한다.
```Dockerfile
FROM flyte-worker:latest
COPY task task
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
```

## task 구성
task, workflow에 대한 각각의 런타임 환경을 매번 맞추기 어려우므로 customa하여 docker image를 생성하여 `ContainerTask`를 사용하도록 한다.

```python
from flytekit import workflow, ContainerTask

run_task = ContainerTask(
    name = "run_task",
    image = "test1234:v1", # 이미지가 flyte sandbox 또는 public docker hub에 올라가 있어야 한다.
    command = ["/usr/bin/sh /run.sh"]
)

@workflow 
def run_batch():
    return run_task()
```
- `command` 인자를 명시하지 않으면 오류가 발생한다.
- `image` : task 런타임 이미지


## Registration
1. 등록할 패키지 이름(`task`)을 serialize한다. flyte에서 task 컨테이너를 생성해서 실행할 때 사용할 이미지를 명시해야 한다. 성공적으로 완료되면 default로 `flyte-package.tgz` 폴더가 생성된다.  
  ```bash
  pyflyte --pkgs task package --image "flyte-worker:latest" -f
  ```
2. flyte admin에 전달하여 등록한다. 등록할 `project`, `domain`, `version` 을 함께 지정해준다.  
  ```bash
  flytectl register files --project flytesnacks --domain staging --archive flyte-package.tgz --version v3
  ```

이 때, **동일한 `project` - `domain`- `version`에서는 같은 이름으로 파일 등록이 불가하다.*


## Flyte내에서 도커 컨테이너 실행

`ContainerTask`로 Task를 구성하면 아래와 같이 먼저 `flytecopilot-releas`라는 도커 이미지를 기반으로 `flyte-copilot-downloader` 컨테이너를 실행한다.(flyte-copilot) flyte propeller 기능을 위한 것으로 보인다.

### Bug Report
아래와 같은 오류가 발생하였다
```bash
Init Containers:
  flyte-copilot-downloader:
    Container ID:  docker://6cef5dc9068e3f14bf8ed66bc2c7bbc24d37e1de5d3a90149cda426faa46902e
    Image:         cr.flyte.org/flyteorg/flytecopilot-release:v1.0.1
    Image ID:      docker-pullable://cr.flyte.org/flyteorg/flytecopilot-release@sha256:1cae52cfd452a707146dd8d4f06faa10d1f2ea45e66a8585201ca896143ea256
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/flyte-copilot
      --storage.limits.maxDownloadMBs=0
      --storage.container=my-s3-bucket
      --storage.type=minio
      --storage.stow.config
      secret_key=miniostorage
      --storage.stow.config
      disable_ssl=1
      --storage.stow.config
      endpoint=http://minio.flyte.svc.cluster.local:9000
      --storage.stow.config
      region=us-east-1
      --storage.stow.config
      access_key_id=minio
      --storage.stow.config
      auth_type=accesskey
      --storage.stow.kind=s3
    Args:
      download
      --from-remote
      s3://my-s3-bucket/metadata/propeller/flytesnacks-staging-aw8tgkrkzmpz24v4gfb5/runtask/data/inputs.pb
      --to-output-prefix
      s3://my-s3-bucket/metadata/propeller/flytesnacks-staging-aw8tgkrkzmpz24v4gfb5/runtask/data/3
      --to-local-dir
      /var/flyte/inputs
      --format
      JSON
      --input-interface

Containers:
  aw8tgkrkzmpz24v4gfb5-runtask-3:
    Container ID:  docker://be2506426f8368bd59b485fb3f072ac1af79997a4fa4ef216092cd74f2b1cbca
    Image:         test1234:v1
    

Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  59s   default-scheduler  Successfully assigned flytesnacks-staging/aw8tgkrkzmpz24v4gfb5-runtask-3 to b0cb91da6f2b
  Normal   Pulled     57s   kubelet            Container image "cr.flyte.org/flyteorg/flytecopilot-release:v1.0.1" already present on machine
  Normal   Created    55s   kubelet            Created container flyte-copilot-downloader
  Normal   Started    55s   kubelet            Started container flyte-copilot-downloader
  Normal   Pulled     54s   kubelet            Container image "test1234:v1" already present on machine
  Normal   Created    52s   kubelet            Created container aw8tgkrkzmpz24v4gfb5-runtask-3
  Warning  Failed     51s   kubelet            Error: .. 
failed to create shim: OCI runtime create failed: container_linux.go:380: starting container process caused: exec: "/usr/bin/sh run.sh": stat /usr/bin/sh run.sh: no such file or directory: unknown..
  Normal   Pulled     51s   kubelet            Container image "cr.flyte.org/flyteorg/flytecopilot-release:v1.0.1" already present on machine
  Normal   Created    50s   kubelet            Created container flyte-copilot-sidecar
  Normal   Started    50s   kubelet            Started container flyte-copilot-sidecar
```