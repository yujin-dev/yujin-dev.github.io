## [23.02.13]
```
go: go.mod file not found in current directory or any parent directory.
```
- 해결 : `go env -w GO111MODULE=auto`
- https://banjubu.tistory.com/130

## [23.03.08]
`I am trying to convert a Go struct to JSON using the json package but all I get is {}.`
- 원인 : `You need to export the User.name field so that the json package can see it.` json으로 바꾸려면 필드명이 대문자로 시작해야 함
- [Converting Go struct to JSON](https://stackoverflow.com/questions/8270816/converting-go-struct-to-json)
- [Exported identifiers](https://go.dev/ref/spec#Exported_identifiers)