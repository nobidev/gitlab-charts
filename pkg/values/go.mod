// Module gitlab.com/gitlab-org/charts/gitlab/pkg/values provides typed Go
// access to the GitLab Helm chart values, generated from
// proto/charts/values/v1/values.proto. The GitLab Operator imports this module
// to work with chart values as typed structs instead of freeform YAML.
module gitlab.com/gitlab-org/charts/gitlab/pkg/values

go 1.24.0

require (
	buf.build/gen/go/bufbuild/protovalidate/protocolbuffers/go v1.36.11-20260415201107-50325440f8f2.1
	buf.build/go/protovalidate v1.2.0
	google.golang.org/protobuf v1.36.11
)

require (
	cel.dev/expr v0.25.1 // indirect
	github.com/antlr4-go/antlr/v4 v4.13.1 // indirect
	github.com/google/cel-go v0.28.0 // indirect
	golang.org/x/exp v0.0.0-20250813145105-42675adae3e6 // indirect
	golang.org/x/text v0.28.0 // indirect
	google.golang.org/genproto/googleapis/api v0.0.0-20250811230008-5f3141c8851a // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20250811230008-5f3141c8851a // indirect
)
