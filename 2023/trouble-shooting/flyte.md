## [23.01.18]
```
Pod failed. No message received from kubernetes.
[xxxxxxxxxxxxxxxxxxxxx-n0-0] terminated with exit code (1). Reason [Error]. Message: 
odule>
    sys.exit(execute_task_cmd())
  File "/usr/local/lib/python3.8/site-packages/click/core.py", line 1130, in __call__
    return self.main(*args, **kwargs)
  File "/usr/local/lib/python3.8/site-packages/click/core.py", line 1055, in main
    rv = self.invoke(ctx)
  File "/usr/local/lib/python3.8/site-packages/click/core.py", line 1404, in invoke
    return ctx.invoke(self.callback, **ctx.params)
  File "/usr/local/lib/python3.8/site-packages/click/core.py", line 760, in invoke
    return __callback(*args, **kwargs)
  File "/usr/local/lib/python3.8/site-packages/flytekit/bin/entrypoint.py", line 468, in execute_task_cmd
    _execute_task(
  File "/usr/local/lib/python3.8/site-packages/flytekit/exceptions/scopes.py", line 160, in system_entry_point
    return wrapped(*args, **kwargs)
  File "/usr/local/lib/python3.8/site-packages/flytekit/bin/entrypoint.py", line 346, in _execute_task
    _handle_annotated_task(ctx, _task_def, inputs, output_prefix)
  File "/usr/local/lib/python3.8/site-packages/flytekit/bin/entrypoint.py", line 289, in _handle_annotated_task
    _dispatch_execute(ctx, task_def, inputs, output_prefix)
  File "/usr/local/lib/python3.8/site-packages/flytekit/bin/entrypoint.py", line 160, in _dispatch_execute
    ctx.file_access.put_data(ctx.execution_state.engine_dir, output_prefix, is_multipart=True)
  File "/usr/local/lib/python3.8/site-packages/flytekit/core/data_persistence.py", line 476, in put_data
    raise FlyteAssertion(
flytekit.exceptions.user.FlyteAssertion: Failed to put data from /tmp/flyte-j30gyo6a/sandbox/local_flytekit/engine_dir to s3://my-s3-bucket/metadata/propeller/alert-development-xxxxxxxxxxxxxxxxxxxxx/n0/data/0 (recursive=True).
다
Original exception: Called process exited with error code: 1.  Stderr dump:

b'upload failed: ../tmp/flyte-j30gyo6a/sandbox/local_flytekit/engine_dir/error.pb to s3://my-s3-bucket/metadata/propeller/alert-development-xxxxxxxxxxxxxxxxxxxxx/n0/data/0/error.pb An error occurred (AccessDenied) when calling the PutObject operation: Access Denied.\n'
.
```
- Flyte 내부적으로 결과값을 s3에 임시로 저장한 후 불러오는데, 권한 오류가 발생하였다.
- workflow 내에서 boto3 모듈을 사용할 경우 발생할 수 있는 이슈이다.