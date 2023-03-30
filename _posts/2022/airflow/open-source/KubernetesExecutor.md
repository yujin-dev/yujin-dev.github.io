## KubernetesExecutor

KubernetesExecutor는 각각의 task를 pod마다 띄워 실행한다. DAG가 제출되면 KubernetesExecutor는 Kubernetes API로 worker pod를 요청한다.

![](https://airflow.apache.org/docs/apache-airflow/stable/_images/arch-diag-kubernetes.png)

![](https://airflow.apache.org/docs/apache-airflow/stable/_images/k8s-happy-path.png)

```python
# executors/kubernetes_executor.py
class KubernetesExecutor(BaseExecutor):
    def __init__(self):
        self.kube_config = KubeConfig()
        self._manager = multiprocessing.Manager()
        self.task_queue: Queue[KubernetesJobType] = self._manager.Queue()
        self.result_queue: Queue[KubernetesResultsType] = self._manager.Queue()
        self.kube_scheduler: AirflowKubernetesScheduler | None = None
        self.kube_client: client.CoreV1Api | None = None
        self.scheduler_job_id: str | None = None
        self.event_scheduler: EventScheduler | None = None
        self.last_handled: dict[TaskInstanceKey, float] = {}
        self.kubernetes_queue: str | None = None
        super().__init__(parallelism=self.kube_config.parallelism)
```
- `start`
    ```python
        def start(self) -> None:
            # checking...
            self.kube_client = get_kube_client()
            self.kube_scheduler = AirflowKubernetesScheduler(
                self.kube_config, self.task_queue, self.result_queue, self.kube_client, self.scheduler_job_id
            )
            self.event_scheduler = EventScheduler()
            self.event_scheduler.call_regular_interval(
                self.kube_config.worker_pods_pending_timeout_check_interval,
                self._check_worker_pods_pending_timeout,
            )

            self.event_scheduler.call_regular_interval(
                self.kube_config.worker_pods_queued_check_interval,
                self.clear_not_launched_queued_tasks,
            )
            self.clear_not_launched_queued_tasks()
    ```
    executor를 시작하면서 kubernetes scheduler와 event scheduler를 초기화한다.  
    AirflowScheulder는 MetaDB를 통해 워커를 실행시키는 스케줄러이다.
    ```python
    class AirflowKubernetesScheduler(LoggingMixin):
    """Airflow Scheduler for Kubernetes"""

    def __init__(
        self,
        kube_config: Any,
        task_queue: Queue[KubernetesJobType],
        result_queue: Queue[KubernetesResultsType],
        kube_client: client.CoreV1Api,
        scheduler_job_id: str,
    ):
        super().__init__()
        self.log.debug("Creating Kubernetes executor")
        self.kube_config = kube_config
        self.task_queue = task_queue
        self.result_queue = result_queue
        self.namespace = self.kube_config.kube_namespace
        self.log.debug("Kubernetes using namespace %s", self.namespace)
        self.kube_client = kube_client
        self._manager = multiprocessing.Manager()
        self.watcher_queue = self._manager.Queue()
        self.scheduler_job_id = scheduler_job_id
        self.kube_watcher = self._make_kube_watcher()
    ```

- `execute_async`
    ```python
        def execute_async(
            self,
            key: TaskInstanceKey,
            command: CommandType,
            queue: str | None = None,
            executor_config: Any | None = None,
        ) -> None:
            # checking...
            self.event_buffer[key] = (State.QUEUED, self.scheduler_job_id)
            self.task_queue.put((key, command, kube_executor_config, pod_template_file))
            # We keep a temporary local record that we've handled this so we don't
            # try and remove it from the QUEUED state while we process it
            self.last_handled[key] = time.time()
    ```
    `event_buffer`는 상속받은 BaseExecutor의 `Dictionary[TaskInstanceKey, EventBufferValueType]` 변수이다.
- `sync`
    ```python
        def sync(self) -> None: # --1
            # checking...
            self.kube_scheduler.sync()

            last_resource_version = None
            while True:
                try:
                    results = self.result_queue.get_nowait()
                    try:
                        key, state, pod_id, namespace, resource_version = results
                        last_resource_version = resource_version
                        self.log.info("Changing state of %s to %s", results, state)
                        try:
                            self._change_state(key, state, pod_id, namespace)
                        except Exception as e:
                            self.log.exception(
                                "Exception: %s when attempting to change state of %s to %s, re-queueing.",
                                e,
                                results,
                                state,
                            )
                            self.result_queue.put(results)
                    finally:
                        self.result_queue.task_done()
                except Empty:
                    break
    ```
    exception 확인 후 `kube_scheduler.sync`를 실행한다. `kube_scheduler.sync`는 현재 돌아가는 모든 k8s jobs을 확인하여 완료된 작업이 있으면 `result_queue`에 추가한다.
    ```python
    class AirflowKubernetesScheduler(LoggingMixin):
        def sync(self) -> None:
            self.log.debug("Syncing KubernetesExecutor")
            self._health_check_kube_watcher()
            while True:
                try:
                    task = self.watcher_queue.get_nowait()
                    try:
                        self.log.debug("Processing task %s", task)
                        self.process_watcher_task(task)
                    finally:
                        self.watcher_queue.task_done()
                except Empty:
                    break

        def process_watcher_task(self, task: KubernetesWatchType) -> None:
        """Process the task by watcher."""
            pod_id, namespace, state, annotations, resource_version = task
            self.log.debug(
                "Attempting to finish pod; pod_id: %s; state: %s; annotations: %s", pod_id, state, annotations
            )
            key = annotations_to_key(annotations=annotations)
            if key:
                self.log.debug("finishing job %s - %s (%s)", key, state, pod_id)
                self.result_queue.put((key, state, pod_id, namespace, resource_version))
    ```
    이후 `KubernetesExecutor.sync`는 다음과 이어진다. `worker_pods_creation_batch_size`에 맞춰 순차적으로 `task_queue`에서 task를 뽑아 `kube_scheduler.run_next`에 인자로 넣어 실행한다.
    ```python
        def sync(self) -> None: # --2
            # ...(above # --1)
            resource_instance = ResourceVersion()
            resource_instance.resource_version = last_resource_version or resource_instance.resource_version

            for _ in range(self.kube_config.worker_pods_creation_batch_size):
                try:
                    task = self.task_queue.get_nowait()
                    try:
                        self.kube_scheduler.run_next(task)
                    except PodReconciliationError as e:
                        self.log.error(
                            "Pod reconciliation failed, likely due to kubernetes library upgrade. "
                            "Try clearing the task to re-run.",
                            exc_info=True,
                        )
                        self.fail(task[0], e)
                    except ApiException as e:

                        # These codes indicate something is wrong with pod definition; otherwise we assume pod
                        # definition is ok, and that retrying may work
                        if e.status in (400, 422):
                            self.log.error("Pod creation failed with reason %r. Failing task", e.reason)
                            key, _, _, _ = task
                            self.change_state(key, State.FAILED, e)
                        else:
                            self.log.warning(
                                "ApiException when attempting to run task, re-queueing. Reason: %r. Message: %s",
                                e.reason,
                                json.loads(e.body)["message"],
                            )
                            self.task_queue.put(task)
                    except PodMutationHookException as e:
                        key, _, _, _ = task
                        self.log.error(
                            "Pod Mutation Hook failed for the task %s. Failing task. Details: %s",
                            key,
                            e,
                        )
                        self.fail(key, e)
                    finally:
                        self.task_queue.task_done()
                except Empty:
                    break

            # Run any pending timed events
            next_event = self.event_scheduler.run(blocking=False)
            self.log.debug("Next timed event is in %f", next_event)
    ```
    `kube_scheduler.run_next`는 Job을 인자로 받아 task에 관한 정보를 기반으로 Pod를 구성한다. 구성된 Pod를 기반으로 `run_pod_async` 내부적으로 Pod를 생성하게 된다. `create_namespaced_pod`는 Pod를 생성하는 function으로, kubernete api로 HTTP 요청을 통해 이루어진다. 
    ```python
    class AirflowKubernetesScheduler(LoggingMixin):
        def run_pod_async(self, pod: k8s.V1Pod, **kwargs):
            try:
                pod_mutation_hook(pod)
            except Exception as e:
                raise PodMutationHookException(e)

            sanitized_pod = self.kube_client.api_client.sanitize_for_serialization(pod)
            json_pod = json.dumps(sanitized_pod, indent=2)

            self.log.debug("Pod Creation Request: \n%s", json_pod)
            try:
                resp = self.kube_client.create_namespaced_pod(
                    body=sanitized_pod, namespace=pod.metadata.namespace, **kwargs
                )
                self.log.debug("Pod Creation Response: %s", resp)
            except Exception as e:
                self.log.exception("Exception when attempting to create Namespaced Pod: %s", json_pod)
                raise e
            return resp
            
        def run_next(self, next_job: KubernetesJobType) -> None:
            key, command, kube_executor_config, pod_template_file = next_job

            dag_id, task_id, run_id, try_number, map_index = key

            if command[0:3] != ["airflow", "tasks", "run"]:
                raise ValueError('The command must start with ["airflow", "tasks", "run"].')

            base_worker_pod = get_base_pod_from_template(pod_template_file, self.kube_config)

            if not base_worker_pod:
                raise AirflowException(
                    f"could not find a valid worker template yaml at {self.kube_config.pod_template_file}"
                )

            pod = PodGenerator.construct_pod(
                namespace=self.namespace,
                scheduler_job_id=self.scheduler_job_id,
                pod_id=create_pod_id(dag_id, task_id),
                dag_id=dag_id,
                task_id=task_id,
                kube_image=self.kube_config.kube_image,
                try_number=try_number,
                map_index=map_index,
                date=None,
                run_id=run_id,
                args=command,
                pod_override_object=kube_executor_config,
                base_worker_pod=base_worker_pod,
            )
            # Reconcile the pod generated by the Operator and the Pod
            # generated by the .cfg file
            self.log.info("Creating kubernetes pod for job is %s, with pod name %s", key, pod.metadata.name)
            self.log.debug("Kubernetes running for command %s", command)
            self.log.debug("Kubernetes launching image %s", pod.spec.containers[0].image)

            # the watcher will monitor pods, so we do not block.
            self.run_pod_async(pod, **self.kube_config.kube_client_request_args)
            self.log.debug("Kubernetes Job created!")
    
    # kubernetes/client/api/core_v1_api.py
    class CoreV1Api(object):
        def create_namespaced_pod(self, namespace, body, **kwargs):
            kwargs['_return_http_data_only'] = True
            return self.create_namespaced_pod_with_http_info(namespace, body, **kwargs)

        def create_namespaced_pod_with_http_info(self, namespace, body, **kwargs):
            # ...
            return self.api_client.call_api(
                    '/api/v1/namespaces/{namespace}/pods', 'POST',
                    path_params,
                    query_params,
                    header_params,
                    body=body_params,
                    post_params=form_params,
                    files=local_var_files,
                    response_type='V1Pod',
                    auth_settings=auth_settings,
                    async_req=local_var_params.get('async_req'),
                    _return_http_data_only=local_var_params.get('_return_http_data_only'),
                    _preload_content=local_var_params.get('_preload_content', True),
                    _request_timeout=local_var_params.get('_request_timeout'),
                    collection_formats=collection_formats)
        ```
### `KuberenetesPodOperator`

### CeleryExecutor와 비교
- 일단 KubernetesExecutor는 task마다 Pod에서 실행되는데, task 시작시에 생성되고 종료되면 pod도 삭제되어 리소스 사용 측면에서 더 효율적인 측면이 있다. CeleryExecturo의 경우 일정한 수의 worker가 계속적으로 가동하고 있어야 한다.( 하지만 Celery workers의 수를 0으로 조정하여 스케일링하는 방법도 있다)
- CeleryExecutor의 경우 task가 queued 상태이면 이미 돌아가는 프로세스가 있어 보다 적은 latency가 발생한다. 
- CeleryExecutor는 Redis같은 DB가 필요하나, KuberenetesExecutor는 따로 필요하지 않다.

## CeleryKubernetesExecutor
- `executors/celery_kubernetes_executor.py`

클러스터내에서 CeleryExecutor와 KubernetesExecutor를 동시에 사용이 가능하다. CeleryKubernetesExecutor는 task queue를 통해 Celery에서 실행할 것인지, Kubernetes에서 실행할 것인지 결정한다. default로는 Celery에서 실행하고 Kubernetes에서 실행하고자 하면 `kubernetes` queue에 task를 추가하면 된다.
 
```python
# executors/celery_kubernetes_executor.py
class CeleryKubernetesExecutor(LoggingMixin):
    supports_ad_hoc_ti_run: bool = True
    callback_sink: BaseCallbackSink | None = None

    KUBERNETES_QUEUE = conf.get("celery_kubernetes_executor", "kubernetes_queue")

    def __init__(self, celery_executor: CeleryExecutor, kubernetes_executor: KubernetesExecutor):
        super().__init__()
        self._job_id: int | None = None
        self.celery_executor = celery_executor
        self.kubernetes_executor = kubernetes_executor
        self.kubernetes_executor.kubernetes_queue = self.KUBERNETES_QUEUE
```

CeleryKubernetesExecutor는 celery_executor, kubernetes_executor를 동시에 시작한다.
```python
    def start(self) -> None:
        """Start celery and kubernetes executor"""
        self.celery_executor.start()
        self.kubernetes_executor.start()
```
`_router`에 따라 인자값인 `SimpleTaskInstance`의 queue를 판별하여 `kubernetes_queue`이면 ,`kubernetes_executor`를 반환하고 이외에는 `celery_executor`를 반환하여 해당 Executor queue에 task가 추가한다.
```python
    def _router(self, simple_task_instance: SimpleTaskInstance) -> CeleryExecutor | KubernetesExecutor:
            """
            Return either celery_executor or kubernetes_executor

            :param simple_task_instance: SimpleTaskInstance
            :return: celery_executor or kubernetes_executor
            """
            if simple_task_instance.queue == self.KUBERNETES_QUEUE:
                return self.kubernetes_executor
            return self.celery_executor
        
    def queue_command(
        self,
        task_instance: TaskInstance,
        command: CommandType,
        priority: int = 1,
        queue: str | None = None,
    ) -> None:
        """Queues command via celery or kubernetes executor"""
        executor = self._router(task_instance)
        self.log.debug("Using executor: %s for %s", executor.__class__.__name__, task_instance.key)
        executor.queue_command(task_instance, command, priority, queue)

    def queue_task_instance(
        self,
        task_instance: TaskInstance,
        mark_success: bool = False,
        pickle_id: str | None = None,
        ignore_all_deps: bool = False,
        ignore_depends_on_past: bool = False,
        ignore_task_deps: bool = False,
        ignore_ti_state: bool = False,
        pool: str | None = None,
        cfg_path: str | None = None,
    ) -> None:
        """Queues task instance via celery or kubernetes executor"""
        executor = self._router(SimpleTaskInstance.from_ti(task_instance))
        self.log.debug(
            "Using executor: %s to queue_task_instance for %s", executor.__class__.__name__, task_instance.key
        )
        executor.queue_task_instance(
            task_instance,
            mark_success,
            pickle_id,
            ignore_all_deps,
            ignore_depends_on_past,
            ignore_task_deps,
            ignore_ti_state,
            pool,
            cfg_path,
        )
```
