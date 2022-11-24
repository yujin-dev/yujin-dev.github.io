Airflow에는 여러 [Executor](https://airflow.apache.org/docs/apache-airflow/stable/executor/index.html)가 존재한다.

코드상에는 `airflow/executors`에서 확인할 수 있다.
```
executors
├── __init__.py
├── base_executor.py
├── celery_executor.py
├── celery_kubernetes_executor.py
├── dask_executor.py
├── debug_executor.py
├── executor_constants.py
├── executor_loader.py
├── kubernetes_executor.py
├── local_executor.py
├── local_kubernetes_executor.py
└── sequential_executor.py
```

주요 Executor를 살펴보고자 한다.

## BaseExecutor 
- `executors/base_executor.py`

기본적인 Executor로 Celery, Kubernetes, Local, Sequential같은 Executor type과 통신한다.
```python
class BaseExecutor(LoggingMixin):

    def __init__(self, parallelism: int = PARALLELISM): # parallelism: 한번에 몇개의 job을 실행할지 설정할 수 있다
        super().__init__()
        self.parallelism: int = parallelism
        self.queued_tasks: OrderedDict[TaskInstanceKey, QueuedTaskInstanceType] = OrderedDict()
        self.running: set[TaskInstanceKey] = set()
        self.event_buffer: dict[TaskInstanceKey, EventBufferValueType] = {}
        self.attempts: Counter[TaskInstanceKey] = Counter()
```
다음과 같은 주요 함수는 BaseExecutor를 상속받는 Executor type에서 구현되어 사용된다. 
```python
    def start(self):

    def sync(self) -> None:

    def execute_async(
        self,
        key: TaskInstanceKey,
        command: CommandType,
        queue: str | None = None,
        executor_config: Any | None = None,
    ) -> None:
    
    def end(self) -> None:

    def terminate(self):
```
- `start` : Executors를 시작할 수도 있다.
- `sync` : hearbeat에 의해 주기적으로 호출된다.
- `execute_async` : 비동기적으로 task를 실행한다.
- `end` : caller가 job을 제출하고 끝나길 기다릴 때 사용된다.
- `terminate` : SIGTERM 신호를 받으면 호출된다.

```python
# `executors/base_executor.py` 
    @staticmethod
    def validate_airflow_tasks_run_command(command: list[str]) -> tuple[str | None, str | None]
        if command[0:3] != ["airflow", "tasks", "run"]:
            raise ValueError('The command must start with ["airflow", "tasks", "run"].')
        if len(command) > 3 and "--help" not in command:
            dag_id: str | None = None
            task_id: str | None = None
            for arg in command[3:]:
                if not arg.startswith("--"):
                    if dag_id is None:
                        dag_id = arg
                    else:
                        task_id = arg
                        break
            return dag_id, task_id
        return None, None
```
- `validate_airflow_tasks_run_command`는 전달된 command가 airflow command인지 확인한다. airflow command가 맞으면 dag_id, task_id를 추출하여 반환한다. 아래의  CeleryExecutor, KubernetesExecutor, LocalExecutor, SequentialExecutor에서 사용하게 된다.


## SequentialExecutor
- `executors/sequential_executor.py`

SequentialExecutor는 한번에 하나의 task만을 실행한다. 백엔드로 sqlite를 사용할 수 있는 유일한 Executor이다.(sqlite는 동시 접속을 허용하지 않음)
```python
class SequentialExecutor(BaseExecutor):

    def __init__(self):
        super().__init__()
        self.commands_to_run = []

    def execute_async(
        self,
        key: TaskInstanceKey,
        command: CommandType,
        queue: str | None = None,
        executor_config: Any | None = None,
    ) -> None:

        self.validate_airflow_tasks_run_command(command)
        self.commands_to_run.append((key, command))

    def sync(self) -> None:
        for key, command in self.commands_to_run:
            self.log.info("Executing command: %s", command)

            try:
                subprocess.check_call(command, close_fds=True)
                self.change_state(key, State.SUCCESS)
            except subprocess.CalledProcessError as e:
                self.change_state(key, State.FAILED)
                self.log.error("Failed to execute task %s.", str(e))

        self.commands_to_run = []
```
- `execute_async` : `commands_to_run`라는 queue에 task가 추가된다.
- `sync` : 설정된 `commands_to_run`를 순차적으로 돌면서 subprocess를 생성하여 실행된다.

## LocalExecutor
- `executors/local_executor.py`

LocalExecutor는 로컬에서 tasks를 병렬로 실행시킨다. 내부적으로 Python multiprocessing를 사용한다.
```python
class LocalExecutor(BaseExecutor):

    def __init__(self, parallelism: int = PARALLELISM):
        super().__init__(parallelism=parallelism)
        if self.parallelism < 0:
            raise AirflowException("parallelism must be bigger than or equal to 0")
        self.manager: SyncManager | None = None
        self.result_queue: Queue[TaskInstanceStateType] | None = None
        self.workers: list[QueuedLocalWorker] = []
        self.workers_used: int = 0
        self.workers_active: int = 0
        self.impl: None | (LocalExecutor.UnlimitedParallelism | LocalExecutor.LimitedParallelism) = None
```

```python
    def start(self) -> None:
        ...
        self.result_queue = self.manager.Queue()
        self.workers = []
        self.workers_used = 0
        self.workers_active = 0
        self.impl = (
            LocalExecutor.UnlimitedParallelism(self)
            if self.parallelism == 0
            else LocalExecutor.LimitedParallelism(self)
        )
        self.impl.start()
    def execute_async(
        self,
        key: TaskInstanceKey,
        command: CommandType,
        queue: str | None = None,
        executor_config: Any | None = None,
    ) -> None:
        # check self.impl
        self.validate_airflow_tasks_run_command(command)
        self.impl.execute_async(key=key, command=command, queue=queue, executor_config=executor_config)

    def sync(self) -> None:
        # check self.impl
        self.impl.sync()

    def end(self) -> None:
        # check self.impl and manager
        self.impl.end()
        self.manager.shutdown()
```
- `self.impl`는 2가지로 구분될 수 있다. 인스턴스 생성 시 `parallelism=0`이면 UnLimitedParallelism이고, 그 의외는 LimitedParallelism이 적용된다.
- 각각의 주요 함수가 독립적으로 구현되어 있다.

```python
    class UnlimitedParallelism:
        def __init__(self, executor: LocalExecutor):
            self.executor: LocalExecutor = executor

        def start(self) -> None:
            self.executor.workers_used = 0
            self.executor.workers_active = 0

        def execute_async(
            self,
            key: TaskInstanceKey, 
            command: CommandType,
            queue: str | None = None,
            executor_config: Any | None = None,
        ) -> None:
            # check self.executor.result_queue 
            local_worker = LocalWorker(self.executor.result_queue, key=key, command=command)
            self.executor.workers_used += 1
            self.executor.workers_active += 1
            local_worker.start()

        def sync(self) -> None:
            # check self.executor.result_queue 
            while not self.executor.result_queue.empty():
                results = self.executor.result_queue.get()
                self.executor.change_state(*results)
                self.executor.workers_active -= 1

        def end(self) -> None:
            while self.executor.workers_active > 0:
                self.executor.sync()

```
- `start` : Executor 객체의 `workers_used`, `workers_active` 를 초기화한다.
- `execute_async` : 호출될 때마다 `LocalWorker` 인스턴스를 생성하여 실행한다. 
    - `LocalWorker`는 내부적으로 `multiprocessing.Process`를 상속받는다.  `multiprocessing.Process`는 프로세스를 fork하여 실행된다.
        ```python
        class LocalWorkerBase(Process, LoggingMixin):
            ...
        class LocalWorker(LocalWorkerBase):
            ...
        ```
- `sync` : 호출될 때마다 `result_queue` 비어있는지 확인하여 task가 끝날 때마다 `workers_active`를 하나씩 감소한다.
- `end` : `workers_active` 가 0보다 크면 계속 `sync`를 실행하여 0이 될때까지 계속 호출한다.

```python
    class LimitedParallelism:
        def __init__(self, executor: LocalExecutor):
            self.executor: LocalExecutor = executor
            self.queue: Queue[ExecutorWorkType] | None = None

        def start(self) -> None:
            if not self.executor.manager:
                raise AirflowException(NOT_STARTED_MESSAGE)
            self.queue = self.executor.manager.Queue()
            if not self.executor.result_queue:
                raise AirflowException(NOT_STARTED_MESSAGE)
            self.executor.workers = [
                QueuedLocalWorker(self.queue, self.executor.result_queue)
                for _ in range(self.executor.parallelism)
            ]

            self.executor.workers_used = len(self.executor.workers)

            for worker in self.executor.workers:
                worker.start()

        def execute_async(
            self,
            key: TaskInstanceKey,
            command: CommandType,
            queue: str | None = None,
            executor_config: Any | None = None,
        ) -> None:

            if not self.queue:
                raise AirflowException(NOT_STARTED_MESSAGE)
            self.queue.put((key, command))

        def sync(self):
            while True:
                try:
                    results = self.executor.result_queue.get_nowait()
                    try:
                        self.executor.change_state(*results)
                    finally:
                        self.executor.result_queue.task_done()
                except Empty:
                    break

        def end(self):
            for _ in self.executor.workers:
                self.queue.put((None, None))

            self.queue.join()
            self.executor.sync()

``` 
- `start` : Executor 생성시 `parallelism`에서 설정한 값에 따라 workers를 정해두고 task를 실행한다.
- `execute_sync` : Executor 시작하면서 생성된 queue에 Task key와 command를 전달한다.
- `sync` : `result_queue`에서 task가 끝났는지 확인하면서 계속 확인한다.
- `end` : 설정한 workers에서 순차적으로 queue에서 제거한다.


## CeleryExecutor
- `executors/celery_executor.py`

CeleryExecutor는 Airflow production용으로 사용이 권장된다. 여러 worker node에서 task 실행이 가능하다. celery worker를 시작하려면 `airflow celery worker`를 사전적으로 실행해야 한다.

사전적으로 정의한 configuraion을 기반으로 Celery 인스턴스를 생성하여 사용하게 된다. 
```python
if conf.has_option("celery", "celery_config_options"):
    celery_configuration = conf.getimport("celery", "celery_config_options")
else:
    celery_configuration = DEFAULT_CELERY_CONFIG

app = Celery(conf.get("celery", "CELERY_APP_NAME"), config_source=celery_configuration)
```


```python
class CeleryExecutor(BaseExecutor):

    def __init__(self):
        super().__init__()

        self._sync_parallelism = conf.getint("celery", "SYNC_PARALLELISM")
        if self._sync_parallelism == 0:
            self._sync_parallelism = max(1, cpu_count() - 1)
        self.bulk_state_fetcher = BulkStateFetcher(self._sync_parallelism)
        self.tasks = {}
        self.stalled_task_timeouts: dict[TaskInstanceKey, datetime.datetime] = {}
        self.stalled_task_timeout = datetime.timedelta(
            seconds=conf.getint("celery", "stalled_task_timeout", fallback=0)
        )
        self.adopted_task_timeouts: dict[TaskInstanceKey, datetime.datetime] = {}
        self.task_adoption_timeout = (
            datetime.timedelta(seconds=conf.getint("celery", "task_adoption_timeout", fallback=600))
            or self.stalled_task_timeout
        )
        self.task_publish_retries: Counter[TaskInstanceKey] = Counter()
        self.task_publish_max_retries = conf.getint("celery", "task_publish_max_retries", fallback=3)
```
위에서 사용되는 `BulkStateFetcher`는 여러 Celery tasks 상태를 확인하기 위함이다. 
```python
class BulkStateFetcher(LoggingMixin):
    def __init__(self, sync_parallelism=None):
        super().__init__()
        self._sync_parallelism = sync_parallelism
```

```python
    def sync(self) -> None:
        # check self.tasks
        self.update_all_task_states()
        self._check_for_timedout_adopted_tasks()
        self._check_for_stalled_tasks()

    def end(self, synchronous: bool = False) -> None:
        if synchronous:
            while any(task.state not in celery_states.READY_STATES for task in self.tasks.values()):
                time.sleep(5)
        self.sync()
```
- `sync` : 모든 Task의 상태를 업데이트하고, 상태를 확인한다.
    ```python
    class CeleryExecutor(BaseExecutor):
        def update_all_task_states(self) -> None:
            self.log.debug("Inquiring about %s celery task(s)", len(self.tasks))
            state_and_info_by_celery_task_id = self.bulk_state_fetcher.get_many(self.tasks.values())

            self.log.debug("Inquiries completed.")
            for key, async_result in list(self.tasks.items()):
                state, info = state_and_info_by_celery_task_id.get(async_result.task_id)
                if state:
                    self.update_task_state(key, state, info)

    class BulkStateFetcher(LoggingMixin):
         def get_many(self, async_results) -> Mapping[str, EventBufferValueType]:
             """
                BaseKeyValueStoreBackend : Celery의 result abackend로 사용되면 mget method가 사용된다.
                DatabaseBackend : Celery의 result abackend로 사용되면 데이터 조회를 위해 사용된다.(SELECT)
             """
            if isinstance(app.backend, BaseKeyValueStoreBackend):
                result = self._get_many_from_kv_backend(async_results)
            elif isinstance(app.backend, DatabaseBackend):
                result = self._get_many_from_db_backend(async_results)
            else:
                result = self._get_many_using_multiprocessing(async_results)
            self.log.debug("Fetched %d state(s) for %d task(s)", len(result), len(async_results))
            return result
    
        def _get_many_from_kv_backend(self, async_tasks) -> Mapping[str, EventBufferValueType]:
        task_ids = self._tasks_list_to_task_ids(async_tasks)
        keys = [app.backend.get_key_for_task(k) for k in task_ids]
        values = app.backend.mget(keys)
        ...
        return self._prepare_state_and_info_by_task_dict(task_ids, task_results_by_task_id)

    def _get_many_from_db_backend(self, async_tasks) -> Mapping[str, EventBufferValueType]:
        task_ids = self._tasks_list_to_task_ids(async_tasks)
        session = app.backend.ResultSession()
        task_cls = getattr(app.backend, "task_cls", TaskDb)
        with session_cleanup(session):
            tasks = session.query(task_cls).filter(task_cls.task_id.in_(task_ids)).all()
        ...
        return self._prepare_state_and_info_by_task_dict(task_ids, task_results_by_task_id)

    ```
- `end` : `sync`를 호출한다.

### Task Execution Process
![](https://airflow.apache.org/docs/apache-airflow/stable/_images/run_task_on_celery_executor.png)

위에서 3. Pool Task / 4. Send Task 및 11. Save Celery task state를 확인할 수 있다.

```python
class CeleryExecutor(BaseExecutor):

    def _process_tasks(self, task_tuples: list[TaskTuple]) -> None:
        task_tuples_to_send = [task_tuple[:3] + (execute_command,) for task_tuple in task_tuples]
        first_task = next(t[3] for t in task_tuples_to_send)

        cached_celery_backend = first_task.backend

        key_and_async_results = self._send_tasks_to_celery(task_tuples_to_send)
        self.log.debug("Sent all tasks.")

        for key, _, result in key_and_async_results:
            
            # result가 None이 아니면
                self.update_task_state(key, result.state, getattr(result, "info", None))


class BaseExecutor(LoggingMixin):

    def trigger_tasks(self, open_slots: int) -> None:
        
        sorted_queue = self.order_queued_tasks_by_priority()
        task_tuples = []
        # queued_tasks에서 self.running에 포함되어 있지 않으면 task_tuples에 추가
        if task_tuples:
            self._process_tasks(task_tuples)
```
task를 실행(처리)하는 것으로 보이는 `_process_tasks`는 상속받는 객체의 `trigger_tasks`에서 실행된다 내부적으로 `_send_tasks_to_celery`를 실행하게 된다.


```python
class CeleryExecutor(BaseExecutor):

    def _send_tasks_to_celery(self, task_tuples_to_send: list[TaskInstanceInCelery]): 
        if len(task_tuples_to_send) == 1 or self._sync_parallelism == 1:
            return list(map(send_task_to_executor, task_tuples_to_send))

        # Use chunks instead of a work queue to reduce context switching
        # since tasks are roughly uniform in size
        chunksize = self._num_tasks_per_send_process(len(task_tuples_to_send))
        num_processes = min(len(task_tuples_to_send), self._sync_parallelism)

        with ProcessPoolExecutor(max_workers=num_processes) as send_pool:
            key_and_async_results = list(
                send_pool.map(send_task_to_executor, task_tuples_to_send, chunksize=chunksize)
            )
        return key_and_async_results

```
task_tuples를 인자로 하여 실행시킬 task를 병렬로 `send_task_to_executor`에 전달한다.

`send_task_to_executor`는 `apply_async` 호출을 통해 Celery Task를 실행하는 것으로 보인다.
```python
def send_task_to_executor(
    task_tuple: TaskInstanceInCelery,
) -> tuple[TaskInstanceKey, CommandType, AsyncResult | ExceptionWithTraceback]:
    
    key, command, queue, task_to_run = task_tuple
    try:
        with timeout(seconds=OPERATION_TIMEOUT):
            result = task_to_run.apply_async(args=[command], queue=queue)
    except Exception as e:
        exception_traceback = f"Celery Task ID: {key}\n{traceback.format_exc()}"
        result = ExceptionWithTraceback(e, exception_traceback)

    return key, command, result
```
