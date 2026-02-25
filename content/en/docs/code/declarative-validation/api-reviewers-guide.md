---
title: "API Reviewers Guide"
weight: 30
description: |
  Guidelines for API reviewers on reviewing PRs that use Declarative Validation for new APIs and migrations.
---

# API Reviewers Guide for Declarative Validation

Starting in Kubernetes v1.36, Declarative Validation (DV) is the recommended way to author API validation logic. This means in v1.36+ there will be k8s API PRs that need API review which use Declarative Validation which means API reviewers need to understand how to review DV PRs.  The review should be straightforward as DV's goal is to moving validation logic out of procedural Go code (`validation.go`) and into vetted declarative comment tags directly on the API types (`types.go`).

When reviewing a PR, you will generally encounter one of two scenarios:
- **Scenario A -  New APIs/Fields**: Using DV as the authoritative source of truth from Day 1.
- **Scenario B - Migrations**: Moving existing handwritten validation to DV tags.

**Scenario A** is more important scenario to understand as it should be the common case.

---

## Scenario A: New API Field (Authoritative DV)

When a developer adds a new API or field and wants to use DV, the tags in `types.go` are the *only* validation logic. There should be no fallback handwritten code for these standard rules.

### What to expect:

#### 1. `doc.go` (Enabling Code Generation)
Before tags can be used, the developer must ensure code generation is enabled for the API package.
```go
// +k8s:validation-gen=TypeMeta
// +k8s:validation-gen-input=k8s.io/api/<group>/<version>
package v1
```

#### 2. `types.go` (The Single Source of Truth)
The developer adds standard DV tags directly to the new field. 

**Subresources:** If the API includes a `/status` subresource and validation is needed for it, the root type definition must include the `supportsSubresource` tag.

```go
// +k8s:supportsSubresource="/status"
type MyFeature struct {
    metav1.TypeMeta `json:",inline"`
    // ...
}

type MyNewFeatureSpec struct {
    // +required
    // +k8s:required
    // +k8s:maxLength=256
    // +k8s:format=k8s-short-name
    FeatureName string `json:"featureName"`
}
```

*   **Tags come from the official catalog.** Invented or misspelled tags are silently ignored.
*   **Tags are applied across all API versions.** If the resource has both `v1` and `v1beta1`, tags must appear on both.
*   **No handwritten `Validate*` functions for the same constraints.** The tags are authoritative.

#### 3. `strategy.go` (The Plumbing)
The strategy MUST use `rest.WithDeclarativeEnforcement()`.
```go
func (myStrategy) Validate(ctx context.Context, obj runtime.Object) field.ErrorList {
    // If there is complex cross-field validation, it still lives here
    allErrs := validation.ValidateMyFeature(obj.(*myapi.MyFeature))

    return rest.ValidateDeclarativelyWithMigrationChecks(
        ctx, legacyscheme.Scheme, obj, nil, allErrs, operation.Create, 
        rest.WithDeclarativeEnforcement(), // <--- Critical for New APIs
    )
}
```
*   **`rest.WithDeclarativeEnforcement()` is present.** Without it, every tag in `types.go` is dead code for validation purposes.
*   **Cross-field validation coexists correctly.** Passed in via `allErrs`.

#### 4. `validation_test.go` (The Tests)
Tests for DV rely on marking expected errors to confirm they came from the DV framework.
```go
    expectedErrs: field.ErrorList{
        field.TooLongMaxLength(field.NewPath("spec", "featureName"), 257, 256).MarkNonShadowed(),
    },
```
*   **`.MarkNonShadowed()` is used on expected errors for standard tags.**
*   **Tests verify wiring, not framework logic.** Exhaustive matrix tests for format tags (like `k8s-short-name`) are unnecessary. One or two base cases are sufficient.

#### 5. `zz_generated.validations.go` (The Generated Code)
The PR must include the generated validation code. When a developer adds or changes `+k8s:` tags, they must run `hack/update-codegen.sh validation`.
*   **There is one generated file per API group/version** (e.g., `pkg/apis/core/v1/zz_generated.validations.go`).
*   **The generated file is present in the PR.** 

### ❌ Common Mistakes to Catch (New APIs)

*   **Missing the Enforcement Flag**: If `rest.WithDeclarativeEnforcement()` is missing, the tags are treated as implicit shadows. It will generate a metric mismatch, but the API will *not* reject invalid requests.
*   **Writing Handwritten Fallbacks**: Duplicate validation logic (both tags and Go code) defeats the purpose of DV for new APIs. Redundant hand-written checks should be removed.
*   **Over-Testing Framework Logic**: Exhaustive matrices of tests for standard validation properties. We trust the `validation-gen` framework to implement tags correctly.

---

## Scenario B: Migrating Existing Validation

When migrating *existing* handwritten code, the goal is strict backward compatibility. The DV engine runs the tags alongside the handwritten code, compares the results, and emits metrics if they differ. The declarative errors are shadowed by default.

### What to expect:

1. **`types.go`**: Adds the appropriate DV tag.
2. **`validation.go`**: The old handwritten error *must* be explicitly marked as covered by the new tag using `.MarkCoveredByDeclarative()`.
    ```go
    allErrs = append(allErrs, field.Invalid(...).MarkCoveredByDeclarative())
    ```
3. **`strategy.go`**: Uses `ValidateDeclarativelyWithMigrationChecks` *without* the enforcement flag.
4. **`declarative_validation_test.go`**: Includes an equivalence test using `apitesting.VerifyValidationEquivalence` to ensure no mismatches.

### ❌ Common Mistakes to Catch (Migrations)

*   **Missing Coverage Markers**: If handwritten errors lack `.MarkCoveredByDeclarative()`, the equivalence test will fail with a mismatch.
*   **Incomplete Version Migrations**: Tags must be applied to all versioned API types (e.g., both `v1beta1` and `v1`) to ensure consistent validation.
*   **Path Normalization Issues**: If a field was renamed or moved between versions, the PR must introduce Path Normalization Rules (`rest.WithNormalizationRules`) to map paths correctly before equivalence checks.

---

## FAQ & Cross-Field Validation

**Q: What about cross-field validation (e.g., "Field A is required if Field B is true")?**
A: DV operates on individual fields. It cannot express constraints like "if field A is set, field B must also be set". Complex, cross-field logic must still be implemented in procedural Go code in `validation.go` and passed via `allErrs` to the DV engine.

**Q: Does DV short-circuit validation?**
A: Yes. If a field is missing and marked `+k8s:required`, the framework reports the "required" error and does **not** run further validations on that field (such as `+k8s:minimum`). Handwritten code often needs to be refactored to short-circuit similarly to achieve equivalence during migration.

**Q: Are there any stability constraints on the tags I can use for a new API?**
A: All tags can be used on any API. However, if a tag is explicitly marked as "Alpha" or "Beta" in the Tag Catalog, it generally should not be used as the *sole* authoritative validation for a Stable/GA Kubernetes API.

**Q: What are `+k8s:alpha` and `+k8s:beta` lifecycle prefixes?**
A: These are part of the validation lifecycle mechanism for graduating validation rules on **existing** APIs during migration:
- `+k8s:alpha`: Shadow mode (metrics only, no rejection).
- `+k8s:beta`: Enforced by default, disable-able via the `DeclarativeValidationTakeover` feature gate.
*(For brand-new APIs using `WithDeclarativeEnforcement()`, these prefixes are typically not needed as standard tags are authoritative immediately).*

---

## Summary Checklist for API Reviewers

1. [ ] Are the `+k8s:` tags chosen appropriately from the official catalog?
2. [ ] Are the `zz_generated.validations.go` file(s) updated and included in the PR for each tagged API version?
3. [ ] Are the tags applied consistently across all relevant API versions (v1, v1beta1, etc.)?
4. [ ] For new APIs, is `rest.WithDeclarativeEnforcement()` present in `strategy.go`?
5. [ ] For new APIs, is redundant handwritten validation omitted in favor of the standard tags?
6. [ ] For new APIs, are test expectations correctly identifying the DV errors using `.MarkNonShadowed()`?
7. [ ] Is cross-field logic appropriately left in handwritten code?
8. [ ] For migrations, are the existing handwritten errors tagged with `.MarkCoveredByDeclarative()`?
9. [ ] For migrations, is `VerifyValidationEquivalence` used in tests?