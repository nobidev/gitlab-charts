module gitlab.com/gitlab-org/charts/gitlab/tools/helm-schema-postprocess

go 1.24.0

require (
	gitlab.com/gitlab-org/charts/gitlab/pkg/values v0.0.0
	google.golang.org/protobuf v1.36.11
)

require buf.build/gen/go/bufbuild/protovalidate/protocolbuffers/go v1.36.11-20260415201107-50325440f8f2.1

replace gitlab.com/gitlab-org/charts/gitlab/pkg/values => ../../pkg/values
