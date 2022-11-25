# Dive into Flyte Source Code

주요 레포에 대한 구조는 다음과 같다.
```
Repo	        Language	    Purpose	Status
------------------------------------------------------------------
flyte	        Kustomize,RST	deployment, documentation, issues
flyteidl	    Protobuf	    gRPC/REST API, Workflow spec
flytepropeller	Go	            execution engine
flyteadmin	    Go	            control plane
flytekit	    Python	        python SDK/tools
flyteconsole	Typescript	    Flyte UI
datacatalog	    Go	            manage input/output artifacts
flyteplugins	Go	            Flyte Backend plugins
flytecopilot	Go	            Sidecar to manage input/output for sdk-less
flytestdlib	    Go	            standard library
flytectl	    Go	            A standalone Flyte CLI
```


### [Flyteidl](https://github.com/flyteorg/flyteidl)
Protobuf 기반의 명세를 구현된 레포이다
- protobuf 기반의 Flyte specification 
- gRPC 기반의 backend API specification
- REST 기반의 Swagger