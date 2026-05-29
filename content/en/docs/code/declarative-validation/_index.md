---
title: Declarative API validation
weight: 50
description: |
  Declarative validation behavior, rollout, feature gates, and validation tags for Kubernetes APIs.
---

Declarative validation lets Kubernetes API authors put common validation rules next to the versioned API types they apply to. Instead of hand-writing every basic check in `validation.go`, API authors add `+k8s:` tags to `types.go`, and `validation-gen` turns those tags into Go validation code.

This does not completely replace handwritten validation as there are complex/bespoke validation rules that cannot easily be expressed as tags for which the best practice is to still use handwritten validation code. The goal is to move the simple, repeated, field-local rules into a form that is easier to review and harder to accidentally drift.

## TLDR of declarative validation usage

- Put validation tags on versioned API types.
- Run `hack/update-codegen.sh` after adding or changing tags.

## Rollout and feature gates

Declarative validation has two separate concerns:

- whether generated validation code runs at all
- whether a particular generated error is returned to the user or only compared against handwritten validation.

The current rollout uses these feature gates:

| Feature gate | Stage | Default | What it does |
| --- | --- | --- | --- |
| `DeclarativeValidation` | GA in v1.36 | `true`, locked to default | Runs declarative validation logic where it has been wired in. `DeclarativeValidationBeta` toggles whether hand-written or declarative validation is authoritative.  This only "turns DV" on for migration cases, it is always on for cases w/ no hand-written fallback logic like in new APIs|
| `DeclarativeValidationBeta` | Beta | `true` | Controls `+k8s:beta` validation rules. When enabled, Beta rules reject invalid requests. When disabled, Beta rules fall back to shadow mode. |
| `DeclarativeValidationTakeover` | Deprecated in v1.36 | n/a | Previously controlled whether declarative validation was authoritative. It is no longer honored, but may still be accepted to avoid unknown-gate errors. |

Migrated validation rules (vs net new declarative validation rules) are staged with lifecycle wrappers:

| Rule shape | Enforcement behavior |
| --- | --- |
| `+k8s:alpha(since: "1.N")=<validator>` | Always shadowed. Handwritten validation wins. Mismatches are reported through metrics. |
| `+k8s:beta(since: "1.N")=<validator>` | DV authoritative when `DeclarativeValidationBeta=true`, shadowed when the gate is disabled. Mismateches are reported through metrics. |
| `<validator>` | Stable/unwrapped. DV always authoritative. |

## Disabling `DeclarativeValidationBeta` {#opt-out}

Cluster administrators can set `DeclarativeValidationBeta=false` to move `+k8s:beta` rules back to shadow mode. This is mostly a rollback valve.

Reasons to consider disabling it:

- Beta declarative validation rejects requests that should still be valid.
- Beta declarative validation allows objects that handwritten validation would have rejected.

For feature gate mechanics, see the Kubernetes [feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/) documentation.

## Tag catalog {#catalog}

Descriptions and stability levels in this table come from `validation-gen` `TagDoc` values when the tag is a validator. A few generator wiring tags do not have validator `TagDoc` values, those are marked as metadata.

| Tag | Description | Stability |
| --- | --- | --- |
| [`+k8s:alpha`](#tag-alpha) | Marks the given payload validation as a Alpha validation of the handwritten validation code. An optional Kubernetes version can be specified. | Beta |
| [`+k8s:beta`](#tag-beta) | Marks the given payload validation as a Beta validation of the handwritten validation code. An optional Kubernetes version can be specified. | Beta |
| [`+k8s:customUnique`](#tag-customUnique) | Indicates that uniqueness validation for this list is implemented via custom, handwritten validation. This disables generation of uniqueness validation for this list. | Beta |
| [`+k8s:eachKey`](#tag-eachKey) | Declares a validation for each value in a map or list. | Beta |
| [`+k8s:eachVal`](#tag-eachVal) | Declares a validation for each value in a map or list. | Alpha |
| [`+k8s:enum`](#tag-enum) | Indicates that a string type is an enum. All constant values of this type are considered values in the enum unless excluded using +k8s:enumExclude. | Stable |
| [`+k8s:enumExclude`](#tag-enumExclude) | Indicates that an constant value is not part of an enum, even if the constant's type is tagged with k8s:enum. May be conditionally excluded via +k8s:ifEnabled(Option)=+k8s:enumExclude or +k8s:ifDisabled(Option)=+k8s:enumExclude. If multiple +k8s:ifEnabled/+k8s:ifDisabled tags are used, the value is excluded if any of the exclude conditions are met. | Alpha |
| [`+k8s:forbidden`](#tag-forbidden) | Indicates that a field may not be specified. | Beta |
| [`+k8s:format`](#tag-format) | Indicates that a string field has a particular format. | Stable |
| [`+k8s:ifDisabled`](#tag-ifDisabled) | Declares a validation that only applies when an option is disabled. | Beta |
| [`+k8s:ifEnabled`](#tag-ifEnabled) | Declares a validation that only applies when an option is enabled. | Beta |
| [`+k8s:ifMode`](#tag-ifMode) | Indicates that this field's validation depends on a mode discriminator. | Beta |
| [`+k8s:immutable`](#tag-immutable) | Indicates that a field may not be updated. | Beta |
| [`+k8s:isSubresource`](#tag-isSubresource) | Mark a type as validation for a specific subresource. | Metadata |
| [`+k8s:item`](#tag-item) | Declares a validation for an item of a slice declared as a +k8s:listType=map. The item to match is declared by providing field-value pair arguments. All key fields must be specified. | Stable |
| [`+k8s:listMapKey`](#tag-listMapKey) | Declares a named sub-field of a list's value-type to be part of the list-map key. | Stable |
| [`+k8s:listType`](#tag-listType) | Declares a list field's semantic type and ownership behavior. atomic: single ownership, set: shared ownership with uniqueness, map: shared ownership with key-based uniqueness. | Stable |
| [`+k8s:maxBytes`](#tag-maxBytes) | Indicates that a string field has a limit on its length in bytes. This could only allow as few as N/4 multi-byte characters. If you want to limit length of characters specifically, use maxLength. | Beta |
| [`+k8s:maxItems`](#tag-maxItems) | Indicates that a list has a limit on its size. | Stable |
| [`+k8s:maxLength`](#tag-maxLength) | Indicates that a string field has a limit on its length in characters. This could allow up to 4*N bytes if multi-byte characters are used. If you want to limit length of bytes specifically, use maxBytes. | Stable |
| [`+k8s:maxProperties`](#tag-maxProperties) | maxProperties provides a limit on properties of an object as defined by JSON schema. In Kubernetes it may only be used to constrain the number of elements on a field defined as a golang map. | Stable |
| [`+k8s:maximum`](#tag-maximum) | Indicates that a numeric field has a maximum value. | Stable |
| [`+k8s:minItems`](#tag-minItems) | Indicates that a list has a minimum size. | Stable |
| [`+k8s:minLength`](#tag-minLength) | Indicates that a string field has a minimum length for its value in characters. This means that the minimum size in bytes is a range from X to 4X if multi-byte characters are allowed. | Stable |
| [`+k8s:minProperties`](#tag-minProperties) | minProperties provides a limit on properties of an object as defined by JSON schema. In Kubernetes it may only be used to constrain the number of elements on a field defined as a golang map. | Stable |
| [`+k8s:minimum`](#tag-minimum) | Indicates that a numeric field has a minimum value. | Stable |
| [`+k8s:modeDiscriminator`](#tag-modeDiscriminator) | Indicates that this field is a discriminator for state-based validation. | Beta |
| [`+k8s:neq`](#tag-neq) | Verifies the field's value is not equal to a specific disallowed value. Supports string, integer, and boolean types. | Alpha |
| [`+k8s:opaqueType`](#tag-opaqueType) | Indicates that any validations declared on the referenced type will be ignored. If a referenced type's package is not included in the generator's current flags, this tag must be set, or code generation will fail (preventing silent mistakes). If the validations should not be ignored, add the type's package to the generator using the --readonly-pkg flag. | Alpha |
| [`+k8s:optional`](#tag-optional) | Indicates that a field is optional to clients. | Stable |
| [`+k8s:required`](#tag-required) | Indicates that a field must be specified by clients. | Stable |
| [`+k8s:subfield`](#tag-subfield) | Declares a validation for a subfield of a struct. | Stable |
| [`+k8s:supportsSubresource`](#tag-supportsSubresource) | Declare supported validation subresources for a type. | Metadata |
| [`+k8s:unionDiscriminator`](#tag-unionDiscriminator) | Indicates that this field is the discriminator for a union. | Beta |
| [`+k8s:unionMember`](#tag-unionMember) | Indicates that this field is a member of a union. | Stable |
| [`+k8s:unique`](#tag-unique) | Declares that a list field's elements are unique. This tag can be used with listType=atomic to add uniqueness constraints, or independently to specify uniqueness semantics. | Beta |
| [`+k8s:update`](#tag-update) | Provides constraints on the allowed update operations of a field. Constraints: NoSet (prevents unset->set transitions), NoUnset (prevents set->unset transitions), NoModify (prevents value changes but allows set/unset transitions), NoAddItem (prevents adding items to a slice or map), NoRemoveItem (prevents removing items from a slice or map). Multiple constraints can be specified using multiple tags. For non-pointer structs, NoSet and NoUnset have no effect as these fields cannot be unset. For slice and map fields, 'unset' means len == 0. Slice item identity for NoAddItem/NoRemoveItem comes from +k8s:listType/+k8s:listMapKey/+k8s:unique, for maps the key is the item identity. NoModify is not supported on slices or maps, use +k8s:eachVal=+k8s:update=NoModify for per-item immutability. On lists, +k8s:eachVal=+k8s:update=NoModify requires listType=map or unique=map, otherwise content changes are not detectable. Examples: +k8s:update=NoModify +k8s:update=NoUnset for set-once fields, +k8s:update=NoSet for fields that must be set at creation or never, +k8s:update=NoAddItem +k8s:update=NoRemoveItem on a listType=map field to freeze the structural shape of the list. | Beta |
| [`+k8s:validateError`](#testing-only-tags) | Always fails code generation (useful for testing). | Alpha |
| [`+k8s:validateFalse`](#testing-only-tags) | Always fails validation (useful for testing). | Alpha |
| [`+k8s:validateTrue`](#testing-only-tags) | Always passes validation (useful for testing). | Alpha |
| [`+k8s:validateTrueAlpha`](#testing-only-tags) | Always passes validation (useful for testing). | Alpha |
| [`+k8s:validateTrueBeta`](#testing-only-tags) | Always passes validation (useful for testing). | Beta |
| [`+k8s:zeroOrOneOfMember`](#tag-zeroOrOneOfMember) | Indicates that this field is a member of a zero-or-one-of union. | Stable |

## Tag reference

### `+k8s:alpha` {#tag-alpha}

Marks the given payload validation as a Alpha validation of the handwritten validation code. An optional Kubernetes version can be specified.

- Argument `since`: The Kubernetes version (e.g. `1.34`) at which this validation was added.
- Payload `<validation-tag>`: The validation tag to evaluate as a Alpha validation.

```go
type MyStruct struct {
    // +k8s:alpha(since: "1.36")=+k8s:minimum=1
    MyField int `json:"myField"`
}
```

Do not use this to try to disable handwritten validation. It only controls the lifecycle stage of the generated rule.

### `+k8s:beta` {#tag-beta}

Marks the given payload validation as a Beta validation of the handwritten validation code. An optional Kubernetes version can be specified.

- Argument `since`: The Kubernetes version (e.g. `1.34`) at which this validation was added.
- Payload `<validation-tag>`: The validation tag to evaluate as a Beta validation.

```go
type MyStruct struct {
    // +k8s:beta(since: "1.37")=+k8s:minimum=1
    MyField int `json:"myField"`
}
```

### `+k8s:customUnique` {#tag-customUnique}

Indicates that uniqueness validation for this list is implemented via custom, handwritten validation. This disables generation of uniqueness validation for this list.

```go
type MyStruct struct {
    // +k8s:listType=set
    // +k8s:customUnique
    Names []string `json:"names"`
}
```

### `+k8s:eachKey` {#tag-eachKey}

Declares a validation for each value in a map or list.

- Payload `<validation-tag>`: The tag to evaluate for each key.

```go
type MyStruct struct {
    // +k8s:eachKey=+k8s:minimum=1
    MyMap map[int]string `json:"myMap"`
}
```

In this case every key in `MyMap` must be at least `1`.

### `+k8s:eachVal` {#tag-eachVal}

Declares a validation for each value in a map or list.

- Payload `<validation-tag>`: The tag to evaluate for each value.

```go
type MyStruct struct {
    // +k8s:eachVal=+k8s:minimum=1
    MyMap map[string]int `json:"myMap"`
}
```

In this case every value in `MyMap` must be at least `1`.

### `+k8s:enum` {#tag-enum}

Indicates that a string type is an enum. All constant values of this type are considered values in the enum unless excluded using +k8s:enumExclude.

```go
// +k8s:enum
type MyEnum string

const (
    MyEnumA MyEnum = "A"
    MyEnumB MyEnum = "B"
)

type MyStruct struct {
    MyField MyEnum `json:"myField"`
}
```

Generated validation rejects values outside the declared constants.

### `+k8s:enumExclude` {#tag-enumExclude}

Indicates that an constant value is not part of an enum, even if the constant's type is tagged with k8s:enum.
May be conditionally excluded via +k8s:ifEnabled(Option)=+k8s:enumExclude or +k8s:ifDisabled(Option)=+k8s:enumExclude.
If multiple +k8s:ifEnabled/+k8s:ifDisabled tags are used, the value is excluded if any of the exclude conditions are met.

```go
// +k8s:enum
type MyEnum string

const (
    MyEnumA MyEnum = "A"
    MyEnumB MyEnum = "B"

    // +k8s:enumExclude
    MyEnumInternal MyEnum = "Internal"
)
```

### `+k8s:forbidden` {#tag-forbidden}

Indicates that a field may not be specified.

```go
type MyStruct struct {
    // +k8s:forbidden
    MyField string `json:"myField"`
}
```

### `+k8s:format` {#tag-format}

Indicates that a string field has a particular format.

Supported payloads:

- `k8s-extended-resource-name`: This field holds a Kubernetes extended resource name. This is a domain-prefixed name that must not have a `kubernetes.io` or `requests.` prefix. When `requests.` is prepended, the result must be a valid label key, as used by quota.
- `k8s-label-key`: This field holds a Kubernetes label key.
- `k8s-label-value`: This field holds a Kubernetes label value.
- `k8s-long-name`: This field holds a Kubernetes "long name", aka a "DNS subdomain" value.
- `k8s-long-name-caseless`: Deprecated: This field holds a case-insensitive Kubernetes "long name", aka a "DNS subdomain" value.
- `k8s-path-segment-name`: This field holds a Kubernetes "path segment name" value.
- `k8s-resource-fully-qualified-name`: This field holds a Kubernetes resource "fully qualified name" value. A fully qualified name must not be empty and must be composed of a prefix and a name, separated by a slash (e.g., "prefix/name"). The prefix must be a DNS subdomain, and the name part must be a C identifier with no more than 32 characters.
- `k8s-resource-pool-name`: This field holds value with one or more Kubernetes "long name" parts separated by `/` and no longer than 253 characters.
- `k8s-short-name`: This field holds a Kubernetes "short name", aka a "DNS label" value.
- `k8s-uuid`: This field holds a Kubernetes UUID, which conforms to RFC 4122.

```go
type MyStruct struct {
    // +k8s:format=k8s-label-key
    LabelKey string `json:"labelKey"`

    // +k8s:format=k8s-uuid
    UID string `json:"uid"`
}
```

### `+k8s:ifDisabled` {#tag-ifDisabled}

Declares a validation that only applies when an option is disabled.

- Argument: `<option>`.
- Payload `<validation-tag>`: This validation tag will be evaluated only if the validation option is disabled.

```go
type MyStruct struct {
    // +k8s:ifDisabled(MyFeature)=+k8s:required
    MyField string `json:"myField"`
}
```

### `+k8s:ifEnabled` {#tag-ifEnabled}

Declares a validation that only applies when an option is enabled.

- Argument: `<option>`.
- Payload `<validation-tag>`: This validation tag will be evaluated only if the validation option is enabled.

```go
type MyStruct struct {
    // +k8s:ifEnabled(MyFeature)=+k8s:required
    MyField string `json:"myField"`
}
```

### `+k8s:ifMode` {#tag-ifMode}

Indicates that this field's validation depends on a mode discriminator.

- Positional argument `<string>`: the value of the mode discriminator for which this validation applies.
- Argument `modality` (`<string>`): the name of the discriminator group.
- Argument `mode` (`<string>`): the mode value for which this validation applies.
- Payload: `<validation-tag>`.

```go
type MyStruct struct {
    // +k8s:modeDiscriminator
    Mode string `json:"mode"`

    // +k8s:ifMode("External")=+k8s:required
    External *ExternalConfig `json:"external,omitempty"`
}
```

### `+k8s:immutable` {#tag-immutable}

Indicates that a field may not be updated.

```go
type MyStruct struct {
    // +k8s:immutable
    Name string `json:"name"`
}
```

### `+k8s:isSubresource` {#tag-isSubresource}

Marks a type as the validation shape for a specific subresource.

It depends on `+k8s:supportsSubresource` on the root resource type. Without that matching support declaration, generated subresource validation code may exist but not be reachable through the dispatcher.

- Payload: subresource path, such as `"/status"` or `"/scale"`.

Root resource type:

```go
// +k8s:supportsSubresource="/scale"
type MyResource struct {
    Spec   MySpec   `json:"spec,omitempty"`
    Status MyStatus `json:"status,omitempty"`
}
```

Subresource type:

```go
// +k8s:isSubresource="/scale"
type MyResourceScale struct {
    Spec   ScaleSpec   `json:"spec,omitempty"`
    Status ScaleStatus `json:"status,omitempty"`
}
```

Use this when subresource validation needs to live separately from root-object validation.

### `+k8s:item` {#tag-item}

Declares a validation for an item of a slice declared as a +k8s:listType=map. The item to match is declared by providing field-value pair arguments. All key fields must be specified.

Arguments must be named with the JSON names of the list-map key fields. Values can be strings, integers, or booleans. For example: +k8s:item(name: "myname", priority: 10, enabled: true)=<chained-validation-tag>

- Payload `<validation-tag>`: The tag to evaluate for the matching list item.

```go
type MyStruct struct {
    // +k8s:listType=map
    // +k8s:listMapKey=type
    // +k8s:item(type: "Approved")=+k8s:zeroOrOneOfMember
    // +k8s:item(type: "Denied")=+k8s:zeroOrOneOfMember
    MyConditions []MyCondition `json:"conditions"`
}

type MyCondition struct {
    Type   string `json:"type"`
    Status string `json:"status"`
}
```

Here only the items with `type: "Approved"` or `type: "Denied"` get the nested validation.

### `+k8s:listMapKey` {#tag-listMapKey}

Declares a named sub-field of a list's value-type to be part of the list-map key.

- Payload `<field-json-name>`: The name of the field.

```go
// +k8s:listType=map
// +k8s:listMapKey=keyFieldOne
// +k8s:listMapKey=keyFieldTwo
type MyList []MyStruct

type MyStruct struct {
    KeyFieldOne string `json:"keyFieldOne"`
    KeyFieldTwo string `json:"keyFieldTwo"`
    ValueField   string `json:"valueField"`
}
```

### `+k8s:listType` {#tag-listType}

Declares a list field's semantic type and ownership behavior. atomic: single ownership, set: shared ownership with uniqueness, map: shared ownership with key-based uniqueness.

- Payload `<type>`: atomic | map | set.

```go
// +k8s:listType=map
// +k8s:listMapKey=keyField
type MyList []MyStruct

type MyStruct struct {
    KeyField   string `json:"keyField"`
    ValueField string `json:"valueField"`
}
```

### `+k8s:maxBytes` {#tag-maxBytes}

Indicates that a string field has a limit on its length in bytes.
This could only allow as few as N/4 multi-byte characters.
If you want to limit length of characters specifically, use maxLength.

- Payload `<non-negative integer>`: This field must be no more than X bytes long.

```go
type MyStruct struct {
    // +k8s:maxBytes=64
    Token string `json:"token"`
}
```

### `+k8s:maxItems` {#tag-maxItems}

Indicates that a list has a limit on its size.

- Payload `<non-negative integer>`: This list must be no more than X items long.

```go
type MyStruct struct {
    // +k8s:maxItems=5
    MyList []string `json:"myList"`
}
```

### `+k8s:maxLength` {#tag-maxLength}

Indicates that a string field has a limit on its length in characters.
This could allow up to 4*N bytes if multi-byte characters are used.
If you want to limit length of bytes specifically, use maxBytes.

- Payload `<non-negative integer>`: This field must be no more than X characters long.

```go
type MyStruct struct {
    // +k8s:maxLength=10
    MyString string `json:"myString"`
}
```

### `+k8s:maxProperties` {#tag-maxProperties}

maxProperties provides a limit on properties of an object as defined by JSON schema. In Kubernetes it may only be used to constrain the number of elements on a field defined as a golang map.

- Payload `<non-negative integer>`: This map must have no more than X properties (where X <= 100000).

```go
type MyStruct struct {
    // +k8s:maxProperties=8
    Labels map[string]string `json:"labels"`
}
```

### `+k8s:maximum` {#tag-maximum}

Indicates that a numeric field has a maximum value.

- Payload `<integer>`: This field must be less than or equal to X.

```go
type MyStruct struct {
    // +k8s:maximum=10
    Replicas int `json:"replicas"`
}
```

### `+k8s:minItems` {#tag-minItems}

Indicates that a list has a minimum size.

- Payload `<non-negative integer>`: This list must be at least X items long.

```go
type MyStruct struct {
    // +k8s:minItems=1
    Names []string `json:"names"`
}
```

### `+k8s:minLength` {#tag-minLength}

Indicates that a string field has a minimum length for its value in characters.
This means that the minimum size in bytes is a range from X to 4X if multi-byte characters are allowed.

- Payload `<integer>`: This field must be at least X characters long.

```go
type MyStruct struct {
    // +k8s:minLength=1
    Name string `json:"name"`
}
```

### `+k8s:minProperties` {#tag-minProperties}

minProperties provides a limit on properties of an object as defined by JSON schema. In Kubernetes it may only be used to constrain the number of elements on a field defined as a golang map.

- Payload `<non-negative integer>`: This map must have at least X properties (where X <= 100000).

```go
type MyStruct struct {
    // +k8s:minProperties=1
    Selectors map[string]string `json:"selectors"`
}
```

### `+k8s:minimum` {#tag-minimum}

Indicates that a numeric field has a minimum value.

- Payload `<integer>`: This field must be greater than or equal to X.

```go
type MyStruct struct {
    // +k8s:minimum=0
    MyInt int `json:"myInt"`
}
```

### `+k8s:modeDiscriminator` {#tag-modeDiscriminator}

Indicates that this field is a discriminator for state-based validation.

- Argument `modality` (`<string>`): the name of the discriminator group, if more than one exists.

```go
type MyStruct struct {
    // +k8s:modeDiscriminator
    Mode string `json:"mode"`

    // +k8s:ifMode("File")=+k8s:required
    File *FileSource `json:"file,omitempty"`

    // +k8s:ifMode("URL")=+k8s:required
    URL *URLSource `json:"url,omitempty"`
}
```

### `+k8s:neq` {#tag-neq}

Verifies the field's value is not equal to a specific disallowed value. Supports string, integer, and boolean types.

- Payload `<value>`: The disallowed value. The parser will infer the type (string, int, bool).

```go
type MyStruct struct {
    // +k8s:neq="disallowed"
    MyString string `json:"myString"`

    // +k8s:neq=0
    MyInt int `json:"myInt"`

    // +k8s:neq=true
    MyBool bool `json:"myBool"`
}
```

### `+k8s:opaqueType` {#tag-opaqueType}

Indicates that any validations declared on the referenced type will be ignored. If a referenced type's package is not included in the generator's current flags, this tag must be set, or code generation will fail (preventing silent mistakes). If the validations should not be ignored, add the type's package to the generator using the --readonly-pkg flag.

```go
import "some/external/package"

type MyStruct struct {
    // +k8s:opaqueType
    ExternalField package.ExternalType `json:"externalField"`
}
```

### `+k8s:optional` {#tag-optional}

Indicates that a field is optional to clients.

```go
type MyStruct struct {
    // +k8s:optional
    MyField string `json:"myField"`
}
```

### `+k8s:required` {#tag-required}

Indicates that a field must be specified by clients.

```go
type MyStruct struct {
    // +k8s:required
    MyField string `json:"myField"`
}
```

### `+k8s:subfield` {#tag-subfield}

Declares a validation for a subfield of a struct.

The named subfield must be a direct field of the struct, or of an embedded struct.

- Argument `<field-json-name>`.
- Payload `<validation-tag>`: The tag to evaluate for the subfield.

```go
type Wrapper struct {
    // +k8s:subfield(name)=+k8s:required
    Metadata ObjectMeta `json:"metadata"`
}

type ObjectMeta struct {
    Name string `json:"name"`
}
```

### `+k8s:supportsSubresource` {#tag-supportsSubresource}

Declares which subresources the validation dispatcher should recognize for a root resource type.

- Payload: subresource path, such as `"/status"` or `"/scale"`.
- May be repeated for multiple subresources.

```go
// +k8s:supportsSubresource="/status"
// +k8s:supportsSubresource="/scale"
type MyResource struct {
    Spec   MySpec   `json:"spec,omitempty"`
    Status MyStatus `json:"status,omitempty"`
}
```

If a type has no `+k8s:supportsSubresource` tags, generated validation is only wired for the root resource.

### `+k8s:unionDiscriminator` {#tag-unionDiscriminator}

Indicates that this field is the discriminator for a union.

- Argument `union` (`<string>`): the name of the union, if more than one exists.

```go
type MyStruct struct {
    // +k8s:unionDiscriminator
    Type MyType `json:"type"`

    // +k8s:unionMember
    // +k8s:optional
    OptionA *OptionA `json:"optionA"`

    // +k8s:unionMember
    // +k8s:optional
    OptionB *OptionB `json:"optionB"`
}
```

### `+k8s:unionMember` {#tag-unionMember}

Indicates that this field is a member of a union.

- Argument `union` (`<string>`): the name of the union, if more than one exists.
- Argument `memberName` (`<string>`): the discriminator value for this member.

```go
type MyStruct struct {
    // +k8s:unionMember(union: "backend", memberName: "service")
    // +k8s:optional
    Service *ServiceBackend `json:"service"`

    // +k8s:unionMember(union: "backend", memberName: "resource")
    // +k8s:optional
    Resource *ResourceBackend `json:"resource"`
}
```

### `+k8s:unique` {#tag-unique}

Declares that a list field's elements are unique. This tag can be used with listType=atomic to add uniqueness constraints, or independently to specify uniqueness semantics.

- Payload `<type>`: map | set.

```go
type MyStruct struct {
    // +k8s:listType=atomic
    // +k8s:unique=map
    // +k8s:listMapKey=name
    Ports []Port `json:"ports"`
}

type Port struct {
    Name string `json:"name"`
    Port int32  `json:"port"`
}
```

### `+k8s:update` {#tag-update}

Provides constraints on the allowed update operations of a field. Constraints: NoSet (prevents unset->set transitions), NoUnset (prevents set->unset transitions), NoModify (prevents value changes but allows set/unset transitions), NoAddItem (prevents adding items to a slice or map), NoRemoveItem (prevents removing items from a slice or map). Multiple constraints can be specified using multiple tags. For non-pointer structs, NoSet and NoUnset have no effect as these fields cannot be unset. For slice and map fields, 'unset' means len == 0. Slice item identity for NoAddItem/NoRemoveItem comes from +k8s:listType/+k8s:listMapKey/+k8s:unique, for maps the key is the item identity. NoModify is not supported on slices or maps, use +k8s:eachVal=+k8s:update=NoModify for per-item immutability. On lists, +k8s:eachVal=+k8s:update=NoModify requires listType=map or unique=map, otherwise content changes are not detectable. Examples: +k8s:update=NoModify +k8s:update=NoUnset for set-once fields, +k8s:update=NoSet for fields that must be set at creation or never, +k8s:update=NoAddItem +k8s:update=NoRemoveItem on a listType=map field to freeze the structural shape of the list.

```go
type MyStruct struct {
    // +k8s:update=NoModify
    // +k8s:update=NoUnset
    Token *string `json:"token,omitempty"`

    // +k8s:listType=map
    // +k8s:listMapKey=name
    // +k8s:update=NoAddItem
    // +k8s:update=NoRemoveItem
    Ports []Port `json:"ports"`
}

type Port struct {
    Name string `json:"name"`
    Port int32  `json:"port"`
}
```

```go
type MyStruct struct {
    // +k8s:listType=map
    // +k8s:listMapKey=name
    // +k8s:eachVal=+k8s:update=NoModify
    Ports []Port `json:"ports"`
}
```

### `+k8s:zeroOrOneOfMember` {#tag-zeroOrOneOfMember}

Indicates that this field is a member of a zero-or-one-of union.

A zero-or-one-of union allows at most one member to be set. Unlike regular unions, having no members set is valid.

Warning: This tag should only be used on sets of list items, and never on struct fields directly.

- Argument `union` (`<string>`): the name of the union, if more than one exists.
- Argument `memberName` (`<string>`): the custom member name for this member.

```go
type MyStruct struct {
    // +k8s:listType=map
    // +k8s:listMapKey=type
    // +k8s:item(type: "Foo")=+k8s:zeroOrOneOfMember
    // +k8s:item(type: "Bar")=+k8s:zeroOrOneOfMember
    Conditions []Condition `json:"conditions"`
}

type Condition struct {
    Type   string `json:"type"`
    Status string `json:"status"`
}
```

### Testing-only tags {#testing-only-tags}

`validation-gen` also registers a few tags that are only useful in generator tests:

- `+k8s:validateError`: Always fails code generation (useful for testing).
- `+k8s:validateFalse`: Always fails validation (useful for testing).
- `+k8s:validateTrue`: Always passes validation (useful for testing).
- `+k8s:validateTrueAlpha`: Always passes validation (useful for testing).
- `+k8s:validateTrueBeta`: Always passes validation (useful for testing).

`+k8s:validateError` payload:

- Payload `<string>`: This string will be included in the error message.

`+k8s:validateFalse`, `+k8s:validateTrue`, `+k8s:validateTrueAlpha`, and `+k8s:validateTrueBeta` arguments and payloads:

- Argument `flags` (`<comma-separated-list-of-flag-string>`): values: ShortCircuit, NonError.
- Argument `typeArg` (`<string>`): The type arg in generated code (must be the value-type, not pointer).
- Argument `cohort` (`<string>`): An optional cohort name to group multiple validations.
- Payload `<none>`.
- Payload `<string>`: The generated code will include this string.

```go
type FixtureStruct struct {
    // +k8s:validateFalse="field FixtureStruct.Name"
    Name string `json:"name"`
}
```

## Review checklist

Use this as a quick pass when reviewing a PR that adds declarative validation:

- Are the tags on the versioned API types?
- Did the PR regenerate `zz_generated.validations.go`?
- Did the PR regenerate `test/declarative_validation/<group>/<kind>/zz_generated.validations.main_test.go`?
- Did the PR regenerate `test/declarative_validation/<group>/<kind>/zz_generated.validations.<api-version-*>_test.go`?
- For migrations, does handwritten validation still match the generated result?
- For lifecycle wrappers, is `since:` set to the version where the rule entered that stage?
- For cases where the field is uses as a subresource (ex: `spec.Status.*` fields), is the necessary `+k8s:supportsSubresource` or `+k8s:isSubresource` set?
