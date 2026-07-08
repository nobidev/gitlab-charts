// Command helm-schema-postprocess applies GitLab-specific proto annotations to
// the base JSON Schema produced by protoschema-jsonschema.
//
// It reads the annotations from the compiled proto descriptor (linked in via
// the generated Go packages) and, for every message:
//
//   - rewrites property keys according to the helm_naming convention
//     (snake_case -> lowerCamelCase), honouring field-level helm_name overrides;
//   - rewrites the entries of each "required" array to match; and
//   - adds an "x-gitlab-lifecycle-stage" vendor extension to any property whose
//     field carries a lifecycle_stage annotation.
//
// The transformation is deterministic: Go marshals map keys in sorted order and
// json.Number preserves integer literals, so regenerating yields byte-identical
// output (used by the drift check in spec/proto_values_generation_spec.rb).
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"

	validatepb "buf.build/gen/go/bufbuild/protovalidate/protocolbuffers/go/buf/validate"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/reflect/protoregistry"

	configpb "gitlab.com/gitlab-org/charts/gitlab/pkg/values/gitlab/config"
	// Imported for its init side effect: registering the values proto files in
	// protoregistry.GlobalFiles so their message descriptors resolve by name.
	_ "gitlab.com/gitlab-org/charts/gitlab/pkg/values/charts/values/v1"
)

const defSuffix = ".schema.strict.json"

func main() {
	input := flag.String("input", "", "path to the base JSON Schema bundle")
	output := flag.String("output", "", "path to write the post-processed values.schema.json")
	flag.Parse()

	if *input == "" || *output == "" {
		fmt.Fprintln(os.Stderr, "usage: helm-schema-postprocess --input <bundle.json> --output <values.schema.json>")
		os.Exit(2)
	}

	if err := run(*input, *output); err != nil {
		fmt.Fprintf(os.Stderr, "helm-schema-postprocess: %v\n", err)
		os.Exit(1)
	}
}

func run(input, output string) error {
	data, err := os.ReadFile(input)
	if err != nil {
		return err
	}

	// UseNumber keeps integer literals (for example maximum: 4294967295) exact.
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.UseNumber()
	var root map[string]any
	if err := dec.Decode(&root); err != nil {
		return fmt.Errorf("parsing %s: %w", input, err)
	}

	defs, _ := root["$defs"].(map[string]any)
	if defs == nil {
		return fmt.Errorf("%s: no $defs object found", input)
	}

	// Each $defs key is "<message full name>.schema.strict.json". Resolve the
	// message descriptor from the registry and apply its annotations. This is
	// file-agnostic: it handles messages spread across many proto files in the
	// charts.values.v1 package.
	for key, raw := range defs {
		name, ok := strings.CutSuffix(key, defSuffix)
		if !ok {
			continue
		}
		desc, err := protoregistry.GlobalFiles.FindDescriptorByName(protoreflect.FullName(name))
		if err != nil {
			continue
		}
		md, ok := desc.(protoreflect.MessageDescriptor)
		if !ok {
			continue
		}
		def, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		applyMessage(def, md)
	}

	// google.protobuf.Struct backs every freeform passthrough block. Some of
	// those are null in values.yaml (for example `nodeAffinity:`), so allow null
	// in addition to object.
	if st, ok := defs["google.protobuf.Struct.schema.strict.json"].(map[string]any); ok {
		st["type"] = []any{"object", "null"}
	}

	out, err := json.MarshalIndent(root, "", "  ")
	if err != nil {
		return err
	}
	out = append(out, '\n')
	return os.WriteFile(output, out, 0o644)
}

// makeNullable adds "null" to a node's `type` so an empty (null) values.yaml
// entry validates. Handles both the string and array forms of `type`; a $ref
// node (no `type`) is left unchanged.
func makeNullable(t map[string]any) {
	switch tp := t["type"].(type) {
	case string:
		if tp != "null" {
			t["type"] = []any{tp, "null"}
		}
	case []any:
		for _, x := range tp {
			if x == "null" {
				return
			}
		}
		t["type"] = append(tp, "null")
	}
}

// applyMessage rewrites def to match md:
//   - renames property keys per the helm_naming / helm_name annotations;
//   - adds x-gitlab-lifecycle-stage vendor extensions;
//   - replaces the proto-strict `required` array (which lists every field) with
//     only the fields marked `(buf.validate.field).required`; and
//   - makes every optional field nullable, so a values.yaml key left empty to
//     take a (often template-derived) default validates.
//
// additionalProperties:false from the strict bundle is intentionally kept so
// misspelled keys in a modeled message are flagged. Freeform blocks use
// google.protobuf.Struct, whose $def is an open object, so their contents stay
// unchecked.
func applyMessage(def map[string]any, md protoreflect.MessageDescriptor) {
	conv := messageNaming(md)
	rename := map[string]string{}    // proto field name -> helm property name
	lifecycle := map[string]string{} // helm property name -> lifecycle stage
	required := []any{}              // helm property names of required fields
	fields := md.Fields()
	for i := 0; i < fields.Len(); i++ {
		fd := fields.Get(i)
		helmName := resolveHelmName(fd, conv)
		rename[string(fd.Name())] = helmName
		if stage, ok := lifecycleStage(fd); ok {
			lifecycle[helmName] = stage
		}
		if fieldRequired(fd) {
			required = append(required, helmName)
		}
	}

	if props, ok := def["properties"].(map[string]any); ok {
		renamed := make(map[string]any, len(props))
		for k, v := range props {
			nk := k
			if r, ok := rename[k]; ok {
				nk = r
			}
			if vm, ok := v.(map[string]any); ok {
				if stage, ok := lifecycle[nk]; ok {
					vm["x-gitlab-lifecycle-stage"] = stage
				}
				if !contains(required, nk) {
					makeNullable(vm)
				}
			}
			renamed[nk] = v
		}
		def["properties"] = renamed
	}

	// Replace the strict "everything is required" array with the buf.validate set.
	if len(required) > 0 {
		def["required"] = required
	} else {
		delete(def, "required")
	}
}

func contains(s []any, v string) bool {
	for _, x := range s {
		if x == v {
			return true
		}
	}
	return false
}

// fieldRequired reports whether fd carries `(buf.validate.field).required = true`.
func fieldRequired(fd protoreflect.FieldDescriptor) bool {
	opts := fd.Options()
	if opts == nil || !proto.HasExtension(opts, validatepb.E_Field) {
		return false
	}
	fc, ok := proto.GetExtension(opts, validatepb.E_Field).(*validatepb.FieldRules)
	return ok && fc.GetRequired()
}

// messageNaming returns the helm_naming convention declared on md.
func messageNaming(md protoreflect.MessageDescriptor) configpb.HelmNamingConvention {
	opts := md.Options()
	if opts == nil || !proto.HasExtension(opts, configpb.E_HelmNaming) {
		return configpb.HelmNamingConvention_HELM_NAMING_CONVENTION_UNSPECIFIED
	}
	return proto.GetExtension(opts, configpb.E_HelmNaming).(configpb.HelmNamingConvention)
}

// resolveHelmName returns the Helm property name for fd: a field-level helm_name
// override wins; otherwise a CAMEL_CASE message applies lowerCamelCase; otherwise
// the proto field name is preserved.
func resolveHelmName(fd protoreflect.FieldDescriptor, conv configpb.HelmNamingConvention) string {
	if opts := fd.Options(); opts != nil && proto.HasExtension(opts, configpb.E_HelmName) {
		if name := proto.GetExtension(opts, configpb.E_HelmName).(string); name != "" {
			return name
		}
	}
	if conv == configpb.HelmNamingConvention_HELM_NAMING_CONVENTION_CAMEL_CASE {
		return toLowerCamel(string(fd.Name()))
	}
	return string(fd.Name())
}

// lifecycleStage returns the lowercase lifecycle stage for fd, if annotated.
func lifecycleStage(fd protoreflect.FieldDescriptor) (string, bool) {
	opts := fd.Options()
	if opts == nil || !proto.HasExtension(opts, configpb.E_LifecycleStage) {
		return "", false
	}
	stage := proto.GetExtension(opts, configpb.E_LifecycleStage).(configpb.LifecycleStage)
	if stage == configpb.LifecycleStage_LIFECYCLE_STAGE_UNSPECIFIED {
		return "", false
	}
	return strings.ToLower(strings.TrimPrefix(stage.String(), "LIFECYCLE_STAGE_")), true
}

// toLowerCamel converts a snake_case identifier to lowerCamelCase.
func toLowerCamel(s string) string {
	parts := strings.Split(s, "_")
	var b strings.Builder
	for i, p := range parts {
		if p == "" {
			continue
		}
		if i == 0 {
			b.WriteString(strings.ToLower(p))
			continue
		}
		r := []rune(p)
		r[0] = []rune(strings.ToUpper(string(r[0])))[0]
		b.WriteString(string(r))
	}
	return b.String()
}
