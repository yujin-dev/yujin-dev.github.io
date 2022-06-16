## [GitLab Runner Helm Chart](https://docs.gitlab.com/runner/install/kubernetes.html)

### setup
diff with original gitlab-runner k8s values.yaml
- tags
- executor
- gitlabUrl
- gitlab-runner-secret( register token )
- image 

> references
```
ERROR: Job failed (system failure): prepare environment: setting up credentials: secrets is forbidden: User "system:serviceaccount:gitlab-runner:default" cannot create resource "secrets" in API group "" in the namespace "gitlab-runner"
```
[Private Registry Authentication : set rbac as true](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/318)