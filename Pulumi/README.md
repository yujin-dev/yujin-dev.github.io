> pulumi

## [Architecture](https://www.pulumi.com/docs/intro/concepts/)

pulumi는 코드 플랫폼 인프라이다. 파이썬, Go 같은 프로그래밍 언어와 기본 에코 시스템을 이용하여 pulumi SDK를 통해 상호작용한다.

![](https://www.pulumi.com/images/docs/pulumi-programming-model-diagram.svg)

- 새로운 인프라를 선언하려면 원하는 속성을 가진 Resource 개체를 할당한다. 필요한 경우 stack으로 외부에 속성을 내보낼 수 있다.
- 프로그램은 소스 코드와 실행 방법에 대한 메타 데이터가 포함된 project에 있다. project 디렉토리 안에서 pulumi-cli를 실행하여 셋업한다.

![](https://www.pulumi.com/images/docs/reference/engine-block-diagram.png)

**Language Host**  
pulumi 프로그램을 Deployment Engine에 리소스를 등록할 수 있는 환경을 설정한다.  

**Deployment Engine**   
인프라의 현재 상태를 프로그램에서 설정한 상태로 빌드업하는데 필요한 일련의 작업을 계산한다.  
- 기존 상태를 참조하여 리소스가 이전에 생성되었는지 확인하고 Resource Provider를 통해 생성한다.
- 리소스가 이미 존재하는 경우는 변경 사항을 확인하여 업데이트 가능한지 여부를 확인하고 교체한다.  

**Resource Providers**   
1. Deployment Engine에서 사용하는 binary인 Resource Plugin이 있다. `~/.pulumi/plugins/`를 통해 관리할 수 있다.
2. 각 Resource 유형에 대한 바인딩을 제공하는 SDK이다.

### Project
`Pulumi.yaml`에 포함되는 모든 폴더이다. `pulumi new`를 실행하면 project는 사용할 런타임을 지정하고 배포 중에 실행할 프로그램을 찾을 위치를 결정한다.
로컬 파일 시스템의 리소스를 참조할 때 리소스는 상대적인 경로로 설정된다. 
```python
myTask = Task('myTask',
    spec={
        'build': './app' # subfolder of working directory
        ...
    }
)
```
### Stack
모든 pulumi 프로그램은 stack에 배포된다. stack은 pulumi 프로그램의 독립적인 인스턴스이다.   
여러 개발단계( development/staging/production ) 및 branch를 나타나는데 사용된다.  
`pulumi new`를 통해 project를 시작할 때 스택을 생성한다.

### Resource
리소스는 컴퓨팅 인스턴스, 스토리지 버킷 또는 쿠버네티스 클러스터와 같은 인프라를 구성하는 기본 단위이다.   
모든 인프라는 아래 2개의 하위 클래스 중 하나로 설명된다.
- `CustomerResource` : 사용자 지정 리소스는 AWS, Azure, Google Cloud, Kubernetes와 같은 Resource Provider가 관리하는 리소스이다.
- `ComponentResource` : 구성 요소 리소스는 세부 정보를 추상화한 리소스의 논리적 그룹이다.

### Input/Output
모든 리소스 인자는 input을 허용하여 input은 type값으로 설정한다.  
인스턴스 개체 자체의 모든 리소스 속성은 ouput으로 type값이다.

## AWS vs. Kubernetes
pulumi-kubernetes와 aws-pulumi에서 다른 점은 pulumi-aws에서는 리소스간 의존성을 설정할 수 있어 리소스에 다른 리소스를 사용 가능하다.
의존성이 있는 리소스는 다른 리소스가 생성되기 전에 대기하고 생성이 실패하면 자동으로 생성되지 않는다.  
pulumi-kubernetes에서는 의존성을 따로 표시하지 않아 의존성이 있는 리소스가 있는 경우 계속 대기한다. 의존하는 리소스 생성이 실패해도 이를 인지하지 못해 pending 상태로 넘어간다.


## pulumi-kubernetes

### `kube2pulumi`
yaml파일을 kubernetes pulumi 코드로 변환시켜준다.
- 설치 : `https://github.com/pulumi/kube2pulumi/releases`  
    리눅스이므로 linux-arm64로 적용하여 다운로드받아 압축 해제하였다.
- 사용 :  `kube2pulumi` binary 파일을 사용한다.
    ```console
    $ {kube2pulumi-path} python -f ./pod.yaml
    -----
    __main__.py에 설치된다.
    ```
    