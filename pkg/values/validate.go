// Package values exposes typed access to the GitLab Helm chart values surface,
// generated from proto/charts/values/v1/values.proto, together with a
// protovalidate helper the GitLab Operator can use to validate a decoded values
// document against the buf.validate constraints embedded in the generated
// descriptors (port ranges, enums, required fields, and CEL message rules).
//
// The generated types live in the ./charts/values/v1 subpackage. Import that
// package for the GitLabValues struct, then call Validate on a populated
// message:
//
//	v := &valuesv1.GitLabValues{ /* ... */ }
//	if err := values.Validate(v); err != nil { /* handle invalid values */ }
package values

import (
	"buf.build/go/protovalidate"
	"google.golang.org/protobuf/proto"
)

// Validate checks msg against the buf.validate constraints compiled into the
// generated proto descriptors. It returns nil when the message is valid.
func Validate(msg proto.Message) error {
	v, err := protovalidate.New()
	if err != nil {
		return err
	}
	return v.Validate(msg)
}
