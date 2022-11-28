# [Flytectl](https://github.com/flyteorg/flytectl)

## setup
configuration은 다음과 같이 설정한다.
```bash
admin:
  endpoint: dns:///localhost:30081
  insecure: true # Set to false to enable TLS/SSL connection (not recommended except on local sandbox deployment).
  authType: Pkce # authType: Pkce # if using authentication or just drop this.
```
## verbs
- `flytectl compile` 
- `flytectl completion`
- `flytectl config`
- `flytectl create`
- `flytectl delete`
- `flytectl demo`
- `flytectl get`
- `flytectl register`
- `flytectl sandbox`
- `flytectl update`
- `flytectl upgrade`
- `flytectl version`

위의 각 기능 `flytectl/cmd`에서 확인할 수 있다.

먼저 core를 살펴보자.
```go
func AddCommands(rootCmd *cobra.Command, cmdFuncs map[string]CommandEntry) {
	for resource, cmdEntry := range cmdFuncs {
		cmd := &cobra.Command{
			Use:          resource,
			Short:        cmdEntry.Short,
			Long:         cmdEntry.Long,
			Aliases:      cmdEntry.Aliases,
			RunE:         generateCommandFunc(cmdEntry),
			SilenceUsage: true,
		}

		if cmdEntry.PFlagProvider != nil {
			cmd.Flags().AddFlagSet(cmdEntry.PFlagProvider.GetPFlagSet(""))
		}

		rootCmd.AddCommand(cmd)
	}
}
```
`core/cmd.go`에서 `AddCommands`를 통해 인자로 받은 root commad에 `CommandEntry` 타입의 인자를 추가한다.

### create
```go
/* cmd/create/create.go */

// RemoteCreateCommand will return create Flyte resource commands
func RemoteCreateCommand() *cobra.Command {
	createCmd := &cobra.Command{
		Use:   "create",
		Short: createCmdShort,
		Long:  createCmdLong,
	}
	createResourcesFuncs := map[string]cmdcore.CommandEntry{
		"project": {CmdFunc: createProjectsCommand, Aliases: []string{"projects"}, ProjectDomainNotRequired: true, PFlagProvider: project.DefaultProjectConfig, Short: projectShort,
			Long: projectLong},
		"execution": {CmdFunc: createExecutionCommand, Aliases: []string{"executions"}, ProjectDomainNotRequired: false, PFlagProvider: executionConfig, Short: executionShort,
			Long: executionLong},
	}
	cmdcore.AddCommands(createCmd, createResourcesFuncs)
	return createCmd
}
```
CommandEntry에 포함되는 type은 `project`, `execution`으로 파악된다. 각각의 생성 command는 `create/project.go`, `create/execution.go`에 확인 가능하다.

### get
```go
/* cmd/get/get.go */

// CreateGetCommand will return get command
func CreateGetCommand() *cobra.Command {
	getCmd := &cobra.Command{
		Use:   "get",
		Short: getCmdShort,
		Long:  getCmdLong,
	}

	getResourcesFuncs := map[string]cmdcore.CommandEntry{
		"project": {CmdFunc: getProjectsFunc, Aliases: []string{"projects"}, ProjectDomainNotRequired: true,
			Short: projectShort,
			Long:  projectLong, PFlagProvider: project.DefaultConfig},
		"task": {CmdFunc: getTaskFunc, Aliases: []string{"tasks"}, Short: taskShort,
			Long: taskLong, PFlagProvider: task.DefaultConfig},
		"workflow": {CmdFunc: getWorkflowFunc, Aliases: []string{"workflows"}, Short: workflowShort,
			Long: workflowLong, PFlagProvider: workflow.DefaultConfig},
		"launchplan": {CmdFunc: getLaunchPlanFunc, Aliases: []string{"launchplans"}, Short: launchPlanShort,
			Long: launchPlanLong, PFlagProvider: launchplan.DefaultConfig},
		"execution": {CmdFunc: getExecutionFunc, Aliases: []string{"executions"}, Short: executionShort,
			Long: executionLong, PFlagProvider: execution.DefaultConfig},
		"task-resource-attribute": {CmdFunc: getTaskResourceAttributes, Aliases: []string{"task-resource-attributes"},
			Short: taskResourceAttributesShort,
			Long:  taskResourceAttributesLong, PFlagProvider: taskresourceattribute.DefaultFetchConfig},
		"cluster-resource-attribute": {CmdFunc: getClusterResourceAttributes, Aliases: []string{"cluster-resource-attributes"},
			Short: clusterResourceAttributesShort,
			Long:  clusterResourceAttributesLong, PFlagProvider: clusterresourceattribute.DefaultFetchConfig},
		"execution-queue-attribute": {CmdFunc: getExecutionQueueAttributes, Aliases: []string{"execution-queue-attributes"},
			Short: executionQueueAttributesShort,
			Long:  executionQueueAttributesLong, PFlagProvider: executionqueueattribute.DefaultFetchConfig},
		"execution-cluster-label": {CmdFunc: getExecutionClusterLabel, Aliases: []string{"execution-cluster-labels"},
			Short: executionClusterLabelShort,
			Long:  executionClusterLabelLong, PFlagProvider: executionclusterlabel.DefaultFetchConfig},
		"plugin-override": {CmdFunc: getPluginOverridesFunc, Aliases: []string{"plugin-overrides"},
			Short: pluginOverrideShort,
			Long:  pluginOverrideLong, PFlagProvider: pluginoverride.DefaultFetchConfig},
		"workflow-execution-config": {CmdFunc: getWorkflowExecutionConfigFunc, Aliases: []string{"workflow-execution-config"},
			Short: workflowExecutionConfigShort,
			Long:  workflowExecutionConfigLong, PFlagProvider: workflowexecutionconfig.DefaultFetchConfig, ProjectDomainNotRequired: true},
	}

	cmdcore.AddCommands(getCmd, getResourcesFuncs)

	return getCmd
```
CommandEntry에 포함되는 type은 `project`, `task`, `workflow`, `launchplan`, `execution` 등이 있다. 각각의 생성 command도 마찬가지로 `cmd/get`에서 확인 가능하다.

### update
```go
/* cmd/update/update.go */

// CreateUpdateCommand will return update command
func CreateUpdateCommand() *cobra.Command {
	updateCmd := &cobra.Command{
		Use:   updateUse,
		Short: updateShort,
		Long:  updatecmdLong,
	}
	updateResourcesFuncs := map[string]cmdCore.CommandEntry{
		"launchplan": {CmdFunc: updateLPFunc, Aliases: []string{}, ProjectDomainNotRequired: false, PFlagProvider: launchplan.UConfig,
			Short: updateLPShort, Long: updateLPLong},
		"launchplan-meta": {CmdFunc: getUpdateLPMetaFunc(namedEntityConfig), Aliases: []string{}, ProjectDomainNotRequired: false, PFlagProvider: namedEntityConfig,
			Short: updateLPMetaShort, Long: updateLPMetaLong},
		"project": {CmdFunc: updateProjectsFunc, Aliases: []string{}, ProjectDomainNotRequired: true, PFlagProvider: project.DefaultProjectConfig,
			Short: projectShort, Long: projectLong},
		"execution": {CmdFunc: updateExecutionFunc, Aliases: []string{}, ProjectDomainNotRequired: false, PFlagProvider: execution.UConfig,
			Short: updateExecutionShort, Long: updateExecutionLong},
		"task-meta": {CmdFunc: getUpdateTaskFunc(namedEntityConfig), Aliases: []string{}, ProjectDomainNotRequired: false, PFlagProvider: namedEntityConfig,
			Short: updateTaskShort, Long: updateTaskLong},
		"workflow-meta": {CmdFunc: getUpdateWorkflowFunc(namedEntityConfig), Aliases: []string{}, ProjectDomainNotRequired: false, PFlagProvider: namedEntityConfig,
			Short: updateWorkflowShort, Long: updateWorkflowLong},
		"task-resource-attribute": {CmdFunc: updateTaskResourceAttributesFunc, Aliases: []string{}, PFlagProvider: taskresourceattribute.DefaultUpdateConfig,
			Short: taskResourceAttributesShort, Long: taskResourceAttributesLong, ProjectDomainNotRequired: true},
		"cluster-resource-attribute": {CmdFunc: updateClusterResourceAttributesFunc, Aliases: []string{}, PFlagProvider: clusterresourceattribute.DefaultUpdateConfig,
			Short: clusterResourceAttributesShort, Long: clusterResourceAttributesLong, ProjectDomainNotRequired: true},
		"execution-queue-attribute": {CmdFunc: updateExecutionQueueAttributesFunc, Aliases: []string{}, PFlagProvider: executionqueueattribute.DefaultUpdateConfig,
			Short: executionQueueAttributesShort, Long: executionQueueAttributesLong, ProjectDomainNotRequired: true},
		"execution-cluster-label": {CmdFunc: updateExecutionClusterLabelFunc, Aliases: []string{}, PFlagProvider: executionclusterlabel.DefaultUpdateConfig,
			Short: executionClusterLabelShort, Long: executionClusterLabelLong, ProjectDomainNotRequired: true},
		"plugin-override": {CmdFunc: updatePluginOverridesFunc, Aliases: []string{}, PFlagProvider: pluginoverride.DefaultUpdateConfig,
			Short: pluginOverrideShort, Long: pluginOverrideLong, ProjectDomainNotRequired: true},
		"workflow-execution-config": {CmdFunc: updateWorkflowExecutionConfigFunc, Aliases: []string{}, PFlagProvider: workflowexecutionconfig.DefaultUpdateConfig,
			Short: workflowExecutionConfigShort, Long: workflowExecutionConfigLong, ProjectDomainNotRequired: true},
	}
	cmdCore.AddCommands(updateCmd, updateResourcesFuncs)
	return updateCmd
}
```
CommandEntry에 포함되는 type은 `launchplan`, `launchplan-meta`, `project`, `execution` 등이 있다. 각각의 생성 command도 마찬가지로 `cmd/update`에서 확인 가능하다.

### delete
```go
/* cmd/delete/delete.go */

// RemoteDeleteCommand will return delete command
func RemoteDeleteCommand() *cobra.Command {
	deleteCmd := &cobra.Command{
		Use:   "delete",
		Short: deleteCmdShort,
		Long:  deleteCmdLong,
	}
	terminateResourcesFuncs := map[string]cmdcore.CommandEntry{
		"execution": {CmdFunc: terminateExecutionFunc, Aliases: []string{"executions"}, Short: execCmdShort,
			Long: execCmdLong, PFlagProvider: execution.DefaultExecDeleteConfig},
		"task-resource-attribute": {CmdFunc: deleteTaskResourceAttributes, Aliases: []string{"task-resource-attributes"},
			Short: taskResourceAttributesShort,
			Long:  taskResourceAttributesLong, PFlagProvider: taskresourceattribute.DefaultDelConfig, ProjectDomainNotRequired: true},
		"cluster-resource-attribute": {CmdFunc: deleteClusterResourceAttributes, Aliases: []string{"cluster-resource-attributes"},
			Short: clusterResourceAttributesShort,
			Long:  clusterResourceAttributesLong, PFlagProvider: clusterresourceattribute.DefaultDelConfig, ProjectDomainNotRequired: true},
		"execution-cluster-label": {CmdFunc: deleteExecutionClusterLabel, Aliases: []string{"execution-cluster-labels"},
			Short: executionClusterLabelShort,
			Long:  executionClusterLabelLong, PFlagProvider: executionclusterlabel.DefaultDelConfig, ProjectDomainNotRequired: true},
		"execution-queue-attribute": {CmdFunc: deleteExecutionQueueAttributes, Aliases: []string{"execution-queue-attributes"},
			Short: executionQueueAttributesShort,
			Long:  executionQueueAttributesLong, PFlagProvider: executionqueueattribute.DefaultDelConfig, ProjectDomainNotRequired: true},
		"plugin-override": {CmdFunc: deletePluginOverride, Aliases: []string{"plugin-overrides"},
			Short: pluginOverrideShort,
			Long:  pluginOverrideLong, PFlagProvider: pluginoverride.DefaultDelConfig, ProjectDomainNotRequired: true},
		"workflow-execution-config": {CmdFunc: deleteWorkflowExecutionConfig, Aliases: []string{"workflow-execution-config"},
			Short: workflowExecutionConfigShort,
			Long:  workflowExecutionConfigLong, PFlagProvider: workflowexecutionconfig.DefaultDelConfig, ProjectDomainNotRequired: true},
	}
	cmdcore.AddCommands(deleteCmd, terminateResourcesFuncs)
	return deleteCmd
}
```
CommandEntry에 포함되는 type은 `execution`, `task-resource-attribute`등이 있다. 각각의 생성 command도 마찬가지로 `cmd/delete`에서 확인 가능하다.

### register
```go
/* cmd/register/register.go */

// RemoteRegisterCommand will return register command
func RemoteRegisterCommand() *cobra.Command {
	registerCmd := &cobra.Command{
		Use:   "register",
		Short: registerCmdShort,
		Long:  registercmdLong,
	}
	registerResourcesFuncs := map[string]cmdcore.CommandEntry{
		"files": {CmdFunc: registerFromFilesFunc, Aliases: []string{"file"}, PFlagProvider: rconfig.DefaultFilesConfig,
			Short: registerFilesShort, Long: registerFilesLong},
		"examples": {CmdFunc: registerExamplesFunc, Aliases: []string{"example", "flytesnack", "flytesnacks"}, PFlagProvider: rconfig.DefaultFilesConfig,
			Short: registerExampleShort, Long: registerExampleLong},
	}
	cmdcore.AddCommands(registerCmd, registerResourcesFuncs)
	return registerCmd
}
```
CommandEntry에 포함되는 type은 `files`, `examples`등이 있다. 각각의 생성 command도 마찬가지로 `cmd/register`에서 확인 가능하다.

### CRUD in execution
execution을 예로 각각의 CRUD 디렉토리에서 기능이 구현되어 있다.

```go
/* cmd/create/execution.go */
import (
	"github.com/flyteorg/flyteidl/gen/pb-go/flyteidl/admin"
	...
)
func createExecutionCommand(ctx context.Context, args []string, cmdCtx cmdCore.CommandContext) error {
	...
	if executionConfig.DryRun {
		logger.Debugf(ctx, "skipping CreateExecution request (DryRun)")
	} else {
		exec, _err := cmdCtx.AdminClient().CreateExecution(ctx, executionRequest)
		if _err != nil {
			return _err
		}
		fmt.Printf("execution identifier %v\n", exec.Id)
	}
}
/* cmd/get/execution.go */
func getExecutionFunc(ctx context.Context, args []string, cmdCtx cmdCore.CommandContext) error {
}
/* cmd/update/execution.go */
func updateExecutionFunc(ctx context.Context, args []string, cmdCtx cmdCore.CommandContext) error {
}
/* cmd/delete/execution.go */
func terminateExecutionFunc(ctx context.Context, args []string, cmdCtx cmdCore.CommandContext) error {
}
```

FlyteAdmin과 통신하기 위해 `flyteidl`에서 admin client를 이용한다. 
`flyteidl/clients/go/admin/client.go`를 확인하면 위에서 적용되는 `AdminClient`을 확인할 수 있다. 
```go
func (c Clientset) AdminClient() service.AdminServiceClient {
	return c.adminServiceClient
}
```
`AdminClient`는 `adminService`라는 타입을 반환하는데 아래와 같은 인터페이스를 포함하고 있다. flytectl에서 실제 적용되는 메서드는 `AdminServiceClient`의 내장 함수를 사용하는 것으로 파악된다.
```go
type AdminServiceClient interface {
	// Create and upload a :ref:`ref_flyteidl.admin.Task` definition
	CreateTask(ctx context.Context, in *admin.TaskCreateRequest, opts ...grpc.CallOption) (*admin.TaskCreateResponse, error)
	// Fetch a :ref:`ref_flyteidl.admin.Task` definition.
	GetTask(ctx context.Context, in *admin.ObjectGetRequest, opts ...grpc.CallOption) (*admin.Task, error)
	// Fetch a list of :ref:`ref_flyteidl.admin.NamedEntityIdentifier` of task objects.
	ListTaskIds(ctx context.Context, in *admin.NamedEntityIdentifierListRequest, opts ...grpc.CallOption) (*admin.NamedEntityIdentifierList, error)
	// Fetch a list of :ref:`ref_flyteidl.admin.Task` definitions.
	ListTasks(ctx context.Context, in *admin.ResourceListRequest, opts ...grpc.CallOption) (*admin.TaskList, error)
	// Create and upload a :ref:`ref_flyteidl.admin.Workflow` definition
	CreateWorkflow(ctx context.Context, in *admin.WorkflowCreateRequest, opts ...grpc.CallOption) (*admin.WorkflowCreateResponse, error)
	...
	```