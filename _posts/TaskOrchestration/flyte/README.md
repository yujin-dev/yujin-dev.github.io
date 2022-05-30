
# [Flyte](https://docs.flyte.org/en/latest/index.html)
Flyte is an open-source, container-native, structured programming and distributed processing platform implemented in Golang.

## 실행
### client
```console
$ pyflyte run example.py wf --n 500 --mean 42 --sigma 2
---
DefaultNamedTupleOutput(o0=42.03233910461306, o1=2.04144421035595)
```

### cluster 생성

```console
$ curl -sL https://ctl.flyte.org/install | sudo bash -s -- -b /usr/local/bin
$ export PATH=$(pwd)/bin:$PATH
```
```console
$ flytectl demo start
...
+---------------------------------------------+---------------+-----------+
|                   SERVICE                   |    STATUS     | NAMESPACE |
+---------------------------------------------+---------------+-----------+
| flyte-kubernetes-dashboard-7fd989b99d-6bnn7 | Running       | flyte     |
+---------------------------------------------+---------------+-----------+
| postgres-76c5456bdf-jcwqc                   | Running       | flyte     |
+---------------------------------------------+---------------+-----------+
| minio-699ccf97f9-7pzrf                      | Running       | flyte     |
+---------------------------------------------+---------------+-----------+
Flyte is ready! Flyte UI is available at http://localhost:30080/console
...
```

docker 컨테이너와 k8s 클러스터에서 image애서 받아 default namespace에 pod가 생성됨을 확인할 수 있다.

```console
$ docker ps 

CONTAINER ID   IMAGE                                                                                   COMMAND                  CREATED              STATUS                 PORTS                                                                                                                                                                        NAMES
0f822e335834   cr.flyte.org/flyteorg/flyte-sandbox-lite:sha-5570eff6bd636e07e40b22c79319e46f927519a3   "tini flyte-entrypoi…"   About a minute ago   Up About a minute      0.0.0.0:30080-30082->30080-30082/tcp, 0.0.0.0:30084->30084/tcp, 0.0.0.0:30086->30086/tcp, 2375-2376/tcp, 0.0.0.0:30088-30089->30088-30089/tcp

$ kubectl get pods 
NAME          READY   STATUS      RESTARTS   AGE
py39-cacher   0/1     Completed   0          60s
```

Flyte Cluster에서 실행하려면 `--remote` 옵션을 추가한다.
```console
$ pyflyte run --remote example.py wf --n 500 --mean 42 --sigma 2
Go to http://localhost:30080/console/projects/flytesnacks/domains/development/executions/fbbe1a5dab4f5454cbf9 to see execution in the console.
```
위 URL로 들어가면 아래와 같이 workflow와 task가 생성됨을 확인할 수 있다.

![](./img/dashboard.png)

- `@workflow`로 wrapping된 function은 Workflows에 존재한다.
![](./img/%EC%8A%A4%ED%81%AC%EB%A6%B0%EC%83%B7%2C%202022-05-11%2016-25-08.png)

- `@task`로 wrapping된 function은 Tasks에 존재한다.
![](./img/%EC%8A%A4%ED%81%AC%EB%A6%B0%EC%83%B7%2C%202022-05-11%2016-25-19.png)


## [Architecture]([https://docs.flyte.org/en/latest/concepts/basics.html](https://docs.flyte.org/en/latest/concepts/basics.html))

- Task
    - versioned
    - projects, domains
    - caching/memoization
    - fault tolerance : failure에 대해 retries, timeouts에 적용됨
    - single task execution도 가능
- Workflow
    - **DAG** of units of work encapsulated by nodes
    - defined in `protobuf`
    - accept inputs and produce outputs and re-use task definitions across projects and domains
    - 모든 workflow는 기본적으로 launchplan이 있음
    - **Workflow nodes naturally run in parallel when possible**
    - versioned → {Project, Domain, Name, Version}
- Node
    - a unit of execution or work within a workflow
    - **Tasks are always encapsulated within a node**
    - can have inputs and outputs → used for other nodes
    - Targets
        - Task Nodes → task
        - Workflow Nodes → sub-workflow
        - Branch Nodes → workflow graph
- Launch plans
    - execute workflow
        - can be associated with multiple launch plans
        - but an individual launch plan is always associated with a single, specific workflow
    - 모든 workflow에는 workflow와 동일한 이름의 default launch plan이 있음
- Schedules
    - launch plans와 연동하여 스케줄링이 가능
    - **schedule은 수정이 불가하여** 변경하려면 새로운 version을 생성해야 함
    - Cron Schedule
        
        ```bash
        cron_lp_every_min_of_hour = LaunchPlan.get_or_create(
        name="my_cron_scheduled_lp",
        workflow=date_formatter_wf,
        schedule=CronSchedule(
            schedule="@hourly", # Following schedule runs every hour at beginning of the hour
            kickoff_time_input_arg="kickoff_time",
        ),
        
            )
        ```
        
    - FixedRate Schedule : 정해진 시간 간격에 따라 실행
        
        ```bash
        fixed_rate_lp_days = LaunchPlan.get_or_create(
            name="my_fixed_rate_lp_days",
            workflow=positive_wf,
            schedule=FixedRate(duration=timedelta(days=1)),
            fixed_inputs={"name": "you"}
        )
        ```
        
- Registration
    - Registration에는 Flyte는 workflow를 확인하여 저장
    ![](https://raw.githubusercontent.com/flyteorg/static-resources/main/flyte/concepts/executions/flyte_wf_registration_overview.svg?sanitize=true)

    - **`flytectl register CLI`** 
        - compile the tasks into their serialized representation. During this, the task representation is bound to a container that constitutes the code for the task.
        - compile the workflow into their serialized representation.
    - Launch an execution using the **`FlyteAdmin launch execution API`**
    - **`FlyteAdmin read API`** to get details of the execution
    
    **[ 방법 ]**
    
    1. 실행할 task를 docker image로 빌드하여 serialize하여 사용한다. FlyteAdmin에 등록하기 위해 flytectl register CLI를 실행한다. 여기서 Flyter Cluster 로컬에 이미지를 빌드하여 저장하진 않고 docker hub에서 가져온다.  docker image로 빌드해놓으면 재사용이 용이하다.
    2. docker image를 사용하기 어려운 경우, tar 폴더로 압축하여 등록한다.  
    
    ![Untitled](./img/Untitled13.png)
    
- Executions
    
    ![](https://raw.githubusercontent.com/flyteorg/static-resources/main/flyte/concepts/executions/flyte_wf_execution_overview.svg?sanitize=true)
    
    - workflow execution이 트리거되면 먼저 `getLaunchPlan` 엔드포인트를 호출하여 **launch plan**를 불러온다.
    - user-side에서 input을 설정하고 **FlyteAdmin에 실행을 요청**한다.
    - FlyteAdmin에서 compiled workflow를 패치하여 input과 함께 **executable format으로 변환**시킨다.
    - Kubernetes에서 execution 기록을 DB에 저장하면서 workflow를 시작한다.
    
- Data Types
    - Metadata : inputs, artifacts,..
    - Rawdata : dataframe 같은 실제 데이터
    
    ```bash
    @task
    def my_task(m: int, n: str, o: FlyteFile) -> pd.DataFrame:
    ```
    
    - `FlyteFile` 또는  `pandas.DataFrame` 와 같은 형식이 사용되면 Flyte는 자동적으로 정의된 object-store 경로에서 데이터를 업로드하거나 다운받음
    
    ![](https://raw.githubusercontent.com/flyteorg/static-resources/main/flyte/concepts/data_movement/flyte_data_transfer.png)
    
    - **Flyte는 DataFlow 엔진**으로 데이터 이동을 가능하게 한다.

- Data Catalog
    - Flyte **memoizes task executions** by creating artifacts in DataCatalog
    - Every **task instance** is represented as a **DataSet**
        
        ```bash
        Dataset {
           project: Flyte project the task was registered in
           domain: Flyte domain for the task execution
           name: flyte_task-<taskName>
           version: <cache_version>-<hash(input params)>-<hash(output params)>
        }
        ```
        
    - Every **task execution** is represented as an **Artifact in the Dataset**
        
        ```bash
        Artifact {
           id: uuid
           Metadata: [executionName, executionVersion]
           ArtifactData: [List of ArtifactData]
        }
        
        ArtifactData {
           Name: <output-name>
           value: <offloaded storage location of the literal>
        }
        ```
        
    - Artifact를 불러오기 위한 태그
        
        ```bash
        ArtifactTag {
           Name: flyte_cached-<unique hash of the input values>
        }
        ```
        
    
- FlyteAdmin
    - serves as the main Flyte API to process all client( including FlyteConsole ) requests to the system
    - gRPC, HTTP 요청에 대해 grpc-gateway를 사용하는데 HTTP 요청에 대해 gRPC로 reverse 하기 위함이다.

## [User Guide](https://docs.flyte.org/projects/cookbook/en/latest/index.html)

- Flyte는 data-aware DAG 스케줄링 프로그램이다.
- Flyte는 Docker Container 기반에서 배포된다.
- Flyte에서 workflow 실행은 Kubernetes 리소스로 생성된다.

### Keyword
- Tasks : `@task`
    - caching : `@task(cache=True, cache_version="1.0")` 
    - `ShellTask` : run bash scripts
    - `reference_task` : 이미 정의되어 등록되어 있는 Flyte task
- Workflow : `@workflow` 
- Named Output : output에 명명하여 저장 ex. `wf_outputs = typing.NamedTuple("OP2", greet1=str, greet2=str)`
- Type System : schema를 적용할 수 있고 `StructuredDataset`을 통해 BigQuery나 S3에 dataframe을 write 가능하다.
- Containerization : 격리된 컨테이너에서 Task를 실행할 수 있다. 
    - `ContainerTask`
    - `@task(container_image="...")`로 image를 변경하여 여러 container image를 적용 가능하다.
    - Secret 사용 : ex. `@task(secret_requests=[Secret(group=SECRET_GROUP, key=SECRET_NAME)])`
        ![](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG4gICAgUHJvcGVsbGVyLT4-K1BsdWdpbnM6IENyZWF0ZSBLOHMgUmVzb3VyY2VcbiAgICBQbHVnaW5zLT4-LVByb3BlbGxlcjogUmVzb3VyY2UgT2JqZWN0XG4gICAgUHJvcGVsbGVyLT4-K1Byb3BlbGxlcjogU2V0IExhYmVscyAmIEFubm90YXRpb25zXG4gICAgUHJvcGVsbGVyLT4-K0FwaVNlcnZlcjogQ3JlYXRlIE9iamVjdCAoZS5nLiBQb2QpXG4gICAgQXBpU2VydmVyLT4-K1BvZCBXZWJob29rOiAvbXV0YXRlXG4gICAgUG9kIFdlYmhvb2stPj4rUG9kIFdlYmhvb2s6IExvb2t1cCBnbG9iYWxzXG4gICAgUG9kIFdlYmhvb2stPj4rUG9kIFdlYmhvb2s6IEluamVjdCBTZWNyZXQgQW5ub3RhdGlvbnMgKGUuZy4gSzhzLCBWYXVsdC4uLiBldGMuKVxuICAgIFBvZCBXZWJob29rLT4-LUFwaVNlcnZlcjogTXV0YXRlZCBQb2RcbiAgICBcbiAgICAgICAgICAgICIsIm1lcm1haWQiOnt9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)
    - workflow labels / annotations
- Scheduling workflows : Scheduler를 통해 Launch Plan을 자동으로 실행시킬 수 있다. `CronSchedule`

### Production Config

로컬에서는 Python interpreter에 의존하기 때문에 배포된 Flyte backend를 사용하는 것으로 권장한다.

Workflow 는 아래와 같이 배포한다.
1. Build Dockerfile
```Dockerfile
FROM python:3.8-slim-buster
LABEL org.opencontainers.image.source https://github.com/flyteorg/flytesnacks
...
```
2. Serialize worflows and tasks  
- `make serialize`
- `pyflyte -c sandbox.config --pkgs core serialize --in-container-config-path /root/sandbox.config --local-source-root ${CURDIR} --image ${FULL_IMAGE_NAME}:${VERSION} workflows -f _pb_output/`
 
3. Register workflows and tasks  
- `flytectl register files _pb_output/* -p flytetester -d development --version ${VERSION} --k8sServiceAccount demo --outputLocationPrefix s3://my-s3-bucket/raw_data`

호스팅된 Flyte 환경을 사용하면 리소스( `cpu`, `mem`, `gpu`)를 할당할 수 있는 이점이 있다.  
ex. `@task(requests=Resources(cpu="1", mem="100Mi"), limits=Resources(cpu="2", mem="150Mi"))`


## **Flyte vs. Airflow ?**

- Airflow DAG는 일련의 workflow 작업을 배치로 실행하고 관리하는데 용이하다고 느껴지는 반면 Flyte는 task를 쉽게 테스트하고 이미지로 빌드하여 사용하는데 용이하다고 본다.
    - Task의 아웃풋을 저장할 수 있고 결과물을 캐싱할 수 있어 task를 독립적으로 활용할 수 있다. workflow도 이러한 task를 기반으로 구성된다. 이에 반해 Airflow는 Task를 여러 형태의 Operator로 제공하여 선택적으로 사용하는 방식이다.
    - task를 감싸는 node를 통해 input과 output을 저장하고 이를 다른 task에 전달할 수 있다. ML 파이프라인에서 모델 구축 및 학습에서 활용도가 높을 것으로 기대된다.
    - Airflow에서 workflow를 보다 직관적으로 구현할 수 있다.
- Airflow 클러스터는 로컬에서 KubernetesExecutor, CeleryExecutor, LocalExecutor 등 백엔드 환경 구축에 대한 몇 가지 옵션이 있지만 Flyte는 기본적으로 도커 이미지를 받아 kubernetes에서 실행된다( 설치하면 바로 파드가 생성됨 ).
- Airflow는 기본적으로 스케줄링을 기반으로 한 workflow를 관리하지만 Flyte는 CronSchedule라는 기능을 제공하여 따로 스케줄링을 추가해야 한다.
- Flyte에서는 project와 domain으로 구분하여 namespace가 생성된다.
- **docker image 활용의 차이점**
    - Airflow에서도 `DockerOperator` 나 `KubernetesPodOperator` 로 Task를 구성할 경우 커스터마이즈된 도커 이미지를 사용할 때 DAG 내부에서 Operator를 호출하여 실행된다. 먼저 DAG가 실행되면, 흐름에 따라 Operator가 순서대로 실행되는 방식이다. Operator는 DAG를 구성하는 요소로, 독립적으로 실행될 수 없다.
    - Flyte에서는 Task를 독립적으로 실행할 수 있는데, 유저가 task를 호출하면 Flyte Admin에서 해당 task를 실행시킨다. task는 미리 정의한 도커 이미지를 받아 Pod를 띄워 실행되는데, `flytekit` 를 통해 Flyte와 통신하여 명령을 전달받아 수행된다. 도커 이미지를 직접 생성하는 경우 내부적으로 **flyte에 필요한 의존성 패키지를 설치되어야 오류가 발생하지 않는다.**( 유저가 flytekit을 통해 task 실행을 요청하면 Flyte Admin이 이를 Flyte Propeller에 전달하여 Pod를 띄워 해당 task나 workflow를 실행한다. Pod가 생성되면 `pyflyte-execute ..` 가 수행되는데 이는 flytekit가 필요함을 의미한다.)
    ![](https://raw.githubusercontent.com/flyteorg/static-resources/main/flyte/deployment/sandbox/flyte_sandbox_single_k8s_cluster.png)


## Serialize

### [serialization in python](https://towardsdatascience.com/what-why-and-how-of-de-serialization-in-python-2d4c3b622f6b)
구조화된 객체를 파일 시스템,  DB에 저장하거나 네트워크를 통해 전송할 수 있도록 byte sequence로 변환하는 프로세스를 **serialization**이라고 한다.  
![](https://miro.medium.com/max/1199/1*AUkV8-lhBGTkvpFj_07OUw.png)  

예를 들어 객체를 파일이나 DB에 저장하면 데이터를 전처리하는데 시간을 절약할 수 있다. 데이터를 한번에 전처리하고 디스크에 저장하면 매번 전처리하는 것에 비해 시간이 덜 소요된다.

serialization에는 텍스트 기반과 binary 기반의 두 방식이 있다.  
binary 방식에는 인코딩하는 경우가 포함되고 protobuf, Avro 형식이 있다. 
텍스트 기반에는 csv, json, xml, yaml, toml 등의 형식이 있다. 
파이썬에는 pickle,numpy,pandas 같은 라이브러리를 사용하여 serialize가 가능하다.


