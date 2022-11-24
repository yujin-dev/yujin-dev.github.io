
## KubernetesExecutor
- `executors/kubernetes_executor.py`

KubernetesExecutor는 각각의 task를 pod마다 띄워 실행한다. DAG가 제출되면 KubernetesExecutor는 Kubernetes API로 worker pod를 요청한다.

![](https://airflow.apache.org/docs/apache-airflow/stable/_images/arch-diag-kubernetes.png)


![](https://airflow.apache.org/docs/apache-airflow/stable/_images/k8s-happy-path.png)

```python
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

    def sync(self) -> None:
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

### vs. CeleryExecutor
- 일단 KubernetesExecutor는 task마다 Pod에서 실행되는데, task 시작시에 생성되고 종료되면 pod도 삭제되어 리소스 사용 측면에서 더 효율적인 측면이 있다. CeleryExecturo의 경우 일정한 수의 worker가 계속적으로 가동하고 있어야 한다.( 하지만 Celery workers의 수를 0으로 조정하여 스케일링하는 방법도 있다)
- CeleryExecutor의 경우 task가 queued 상태이면 이미 돌아가는 프로세스가 있어 보다 적은 latency가 발생한다. 
- CeleryExecutor는 Redis같은 DB가 필요하나, KuberenetesExecutor는 따로 필요하지 않다.

## CeleryKubernetesExecutor
- `executors/celery_kubernetes_executor.py`

클러스터내에서 CeleryExecutor와 KubernetesExecutor를 동시에 사용이 가능하다. CeleryKubernetesExecuto는 task queue를 통해 Celery에서 실행할 것인지, Kubernetes에서 실행할 것인지 결정한다. default로는 Celery에서 실행하고 Kubernetes에서 실행하고자 하면 `kubernetes` queue에 task를 추가하면 된다.

