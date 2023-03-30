# [Flyte Propeller](https://github.com/flyteorg/flytepropeller)
Flyte workflow 실행을 스케줄링하고 트래킹한다. FlytePropeller는 컨트롤러를 기반으로 구현된다. 쿠버네티스 컨트롤러는 기본적으로 요청된 상태와 현재 상태를 비교하여 요청 상태로 싱크를 맞춰주는 역할은 한다. 따라서 리소스는 주기적으로 평가되어서 현재 상태를 요청된 상태가 될 수 있도록 한다.

매 루프를 돌 때마다, 요청된 상태와 싱크를 맞추기 위해 FlytePropeller가 동작하여 여러 병렬 작업을 실행할 수 있다.

![](https://raw.githubusercontent.com/flyteorg/static-resources/main/flyte/concepts/architecture/flytepropeller_architecture.png)

## FlyteWorkflow CRD
workflows는 쿠버네티스 Custom Resource Definitions로 관리된다. CRD는 리소스 spec과 status를 포함하고 있다. FlyteWorkflow CRD가 생성 및 업데이트될 때마다 FlytePropeller는 controller/operator API를 통해 변경 사항을 감지한다. FlyteAdmin을 entrypoint로 사용자가 workflow를 실행하거나, relaunch가 있거나, workflow 스케줄링 등으로 인해 FlyteWorkflow CRD가 생성된다. 

`apis/flyteworkflow`를 살펴보면 다음과 같은 구조다.
```
apis
└── flyteworkflow
    ├── crd.go
    ├── register.go
    └── v1alpha1
        ├── branch.go
        ├── node_status.go
        ├── nodes.go
        ├── register.go
        ├── subworkflow.go
        ├── tasks.go
        ├── workflow.go
        └── ...
```
- `apis/flyteworkflow/crd.go` : `k8s.io/apiextensions-apiserver` 패키지를 사용하여 spec을 정의한다.
    ```go
    var (
        CRD                   = apiextensionsv1.CustomResourceDefinition{
            ObjectMeta: metav1.ObjectMeta{
                Name: fmt.Sprintf("flyteworkflows.%s", GroupName),
            },
            Spec: apiextensionsv1.CustomResourceDefinitionSpec{
                Group: GroupName,
                Names: apiextensionsv1.CustomResourceDefinitionNames{
                    ..
                },
                Scope: apiextensionsv1.NamespaceScoped,
                Versions: []apiextensionsv1.CustomResourceDefinitionVersion{
                    ..
                },
            },
        }
    )
    ```
- `apis/flyteworkflow/v1alpha1/workflow.go` : Flyte Workflow에 대한 스펙을 정의한다
    ```go
    // FlyteWorkflow는 Execution Workflow object가 구현된다
    type FlyteWorkflow struct {
        metav1.TypeMeta   `json:",inline"` 
        metav1.ObjectMeta `json:"metadata,omitempty"`
        *WorkflowSpec     `json:"spec"`
        WorkflowMeta      *WorkflowMeta                `json:"workflowMeta,omitempty"`
        Inputs            *Inputs                      `json:"inputs,omitempty"`
        ExecutionID       ExecutionID                  `json:"executionId"`
        Tasks             map[TaskID]*TaskSpec         `json:"tasks"`
        SubWorkflows      map[WorkflowID]*WorkflowSpec `json:"subWorkflows,omitempty"`
        ...
    }
    
    // 다음과 같이 FlyteWorkflow의 속성을 추출하는 함수가 있다. 대부분 struct를 정의하고 struct의 속성을 가져오는 함수로 구성된다. 
    func (in *FlyteWorkflow) GetSecurityContext() core.SecurityContext {
        ...
    }
    func (in *FlyteWorkflow) GetEventVersion() EventVersion {
        ...
    }
    func (in *FlyteWorkflow) GetDefinitionVersion() WorkflowDefinitionVersion {
        ...
    }
    func (in *FlyteWorkflow) GetExecutionConfig() ExecutionConfig {
        ...
    }
    // WorkflowSpec은 실제 FlyteWorkflow인 DAG spec을 명시한다
    type WorkflowSpec struct {
        ID    WorkflowID           `json:"id"`
        Nodes map[NodeID]*NodeSpec `json:"nodes"`

    ```

- `apis/flyteworkflow/v1alpha1/nodes.go` : 노드 스펙을 정의한다
    ```go
    type NodeSpec struct {
        ID            NodeID                        `json:"id"`
        Name          string                        `json:"name,omitempty"`
        Resources     *typesv1.ResourceRequirements `json:"resources,omitempty"`
        Kind          NodeKind                      `json:"kind"`
        BranchNode    *BranchNodeSpec               `json:"branch,omitempty"`
        TaskRef       *TaskID                       `json:"task,omitempty"`
        WorkflowNode  *WorkflowNodeSpec             `json:"workflow,omitempty"`
        InputBindings []*Binding                    `json:"inputBindings,omitempty"`
        ...
    }
    ```

## WorkQueue/WorkerPool
FlytePropeller는 여러 workflows 실행을 지원한다. WorkerPool은 각각의 worker에 대해 여러 고루틴으로 구성된다. 이러한 구조로 하나의 CPU에서도 1000개 이상의 worker를 돌릴 수 있다. worker는 지속적으로 WorkQueue에서 workflow(ID)를 꺼내 WorkflowExecutor로 전달하여 worfklow를 실행한다.

`controller/*.go`를 위주로 살펴본다.

- `controller/controller.go`
    ```go
    // Controller는 FlyteWorkflow 리소스를 위해 구현된 요소이다 
    type Controller struct {
        workerPool          *WorkerPool
        flyteworkflowSynced cache.InformerSynced
        workQueue           CompositeWorkQueue
        gc                  *GarbageCollector
        numWorkers          int
        workflowStore       workflowstore.FlyteWorkflow
        recorder      record.EventRecorder // recorder는 Kubernetes API로 event를 기록하기 위함
        metrics       *metrics
        leaderElector *leaderelection.LeaderElector
        levelMonitor  *ResourceLevelMonitor
    }
    func (c *Controller) run(ctx context.Context) error {
       //Controller의 workerPool을 초기화하고 garbage collector를 시작한다
    }
    func (c *Controller) enqueueFlyteWorkflow(obj interface{}) {
        // Controller의 workQueue에 workflow를 추가한다
    }
    
    ```
- `controller/workers.go`
    ```go
    type WorkerPool struct {
        workQueue CompositeWorkQueue
        metrics   workerPoolMetrics
        handler   Handler
    }
    func (w *WorkerPool) processNextWorkItem(ctx context.Context) bool {
        // workqueue로부터 item을 읽어온다
        obj, shutdown := w.workQueue.Get()
        ...
        defer w.workQueue.Done(obj)
        ...
    }
    func (w *WorkerPool) runWorker(ctx context.Context) {
        // 지속적으로 processNextWorkItem을 호출하여 workqueue로부터 메시지를 읽어와 처리한다
    }
    func (w *WorkerPool) Run(ctx context.Context, threadiness int, synced ...cache.InformerSynced) error {
        // threadiness만큼 고루틴을 생성하여 worker을 실행하게 된다
        ... 
       	for i := 0; i < threadiness; i++ {
		w.metrics.FreeWorkers.Inc()
		logger.Infof(ctx, "Starting worker [%d]", i)
		workerLabel := fmt.Sprintf("worker-%v", i)
		go func() {
			workerCtx := contextutils.WithGoroutineLabel(ctx, workerLabel)
			pprof.SetGoroutineLabels(workerCtx)
			w.runWorker(workerCtx)
		}()
        ...
	}
    ```
- `controller/composite_workqueue.go`
    ```go
    // 다음 2가지에 따라 workqueue에 추가된다
    // 1. Primary Object 자체 : workflow object를 의미한다
    // 2. "Node/Task" updates와 같은 sub-objects가 Ready가 되는 경우에 대한 top-level object
    ```
- `controller/handler.go` : workflow의 실제 상태와 요청된 상태를 비교하여 싱크를 맞춘다. workflow는 ID와 namespace에 따라 식별된다.
    ```go
    func (p *Propeller) Handle(ctx context.Context, namespace, name string) error {
        w, fetchErr := p.wfStore.Get(ctx, namespace, name)
        if len(w.WorkflowClosureReference) > 0 {
            //
        }
    }
    ```

## WorkflowExecutor
workflow operation을 담당한다. 

`controller/workflow`를 위주로 살펴본다.

## NodeExecutor
단일 노드부터 실행되며 workflow의 start node로 시작한다. DFS를 기반으로 선회하고, 각각의 노드를 평가한다. 성공한 노드는 스킵하고, 평가가 되지 않은 노드는 큐에 들어가며, 실패한 노드는 retry된다. 또한 노드 실행 시 중간서 데이터 전송이 가능하도록 readers/writers를 연결한다.( K8s events를 통해 이루어짐 ) 보통 스토리지의 URL 경로를 사용한다. 

`controller/nodes`를 위주로 살펴본다.

## NodeHandler
- TaskHandler(Plugins): Spark, Hive, Snowflake, BigQuery, ..등 플러그인을 실행한다.
- DynamicHandler
- WorkflowHandler 
- BranchHandler
- Start/End Handlers

`controller/nodes`를 위주로 살펴본다.
