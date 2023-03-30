## [23.02.01]
```
error: problem logging in: unable to check if bucket s3://{bucket-name} is accessible: blob (code=Unknown): NoCredentialProviders: no valid providers in chain. Deprecated.
        For verbose messaging see aws.Config.CredentialsChainVerboseErrors
```
- `pulumi login s3://{pulumi-backend-bucket}` 실행하면 발생하는 오류
- 해결 : `pulumi login 's3://{pulumi-backend-bucket}?profile={profile-name}'`  
    [State and Backends](https://www.pulumi.com/docs/intro/concepts/state/)

```
 error: unable to validate AWS credentials - see https://pulumi.io/install/aws.html for details on configuration
```
- 해결 : `pulumi config set aws:profile {profile-name}`로 profile을 설정