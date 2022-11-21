
## Code(Repos) structure

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
It contains:
- Flyte specification with protobuf messages
- backend API specification with gRPC
- Swagger with REST


### [Flyte Propeller](https://github.com/flyteorg/flytepropeller)
It's Kubernetes operator to execute Flyte graphs natively on kubernetes

- Propeller : K8s operator that executes Flyte workflows which is written in Protobuf
- Propeller Webhook : Webhook taht can be optionally deployed to extend Flyte Propeller
- kubectl-flyte : command line used for an extension to kubectl

