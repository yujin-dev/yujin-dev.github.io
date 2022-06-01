# register flyte task - `ContainerTask`

## flyte task 실행을 위한 docker image
flyte 전용 worker container image를 빌드한다.

```console
$ cd flyte-worker-docker
$ docker build . --tag flyte-worker:latest
```

해당 이미지를 기반으로 customize하여 task에 맞는 이미지를 생성할 수 있도록 한다.(Dockerfile)
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


## task 및 workflow 등록
1. 등록할 패키지 이름(`task`)을 serialize한다. flyte에서 task 컨테이너를 생성해서 실행할 때 사용할 이미지를 명시해야 한다. 성공적으로 완료되면 default로 `flyte-package.tgz` 폴더가 생성된다.
```bash
pyflyte --pkgs task package --image "flyte-worker:latest" -f
```

2. flyte admin에 전달하여 등록한다. 등록할 `project`, `domain`, `version` 을 함께 지정해준다.
```bash
flytectl register files --project flytesnacks --domain staging --archive flyte-package.tgz --version v3
```
- 동일한 `project` - `domain`- `version`에서는 같은 이름으로 파일 등록이 불가하다.

