---
title: "Declarative Validation"
weight: 50
description: |
  Overview and architecture of declarative API validation in Kubernetes.
---

This document provides an overview of the Declarative Validation project in Kubernetes, also known as `validation-gen`. This feature allows developers to define validation logic for native Kubernetes API types using Go comment tags (e.g., `+k8s:minimum=0`).

## Architecture overview

The declarative validation system consists of two main components:

1.  **Code Generator (`validation-gen`)**: Parses special `+k8s:` comment tags in API type definitions (`types.go`) and generates Go code (`zz_generated.validations.go`) that enforces these rules.
2.  **Runtime Validation Library**: A set of validation functions that the generated code calls to perform the actual validation (e.g., checking minimums, formats, required fields).

## Key Directories

*   **`staging/src/k8s.io/code-generator/cmd/validation-gen/`**: The main package for the code generator.
    *   **`validators/`**: Contains the definitions for the validation tags themselves (e.g., how `+k8s:required` is parsed and what code it generates).
    *   **`output_tests/tags/`**: Contains tests that verify the generated code for each validation tag.
*   **`staging/src/k8s.io/apimachinery/pkg/api/validate/`**: The runtime library containing the actual validation logic called by the generated code.

## Useful Commands

*   **Regenerate Validation Code**:
    ```bash
    hack/update-codegen.sh validation
    ```
*   **Run `validation-gen` Tests**:
    ```bash
    go test ./staging/src/k8s.io/code-generator/cmd/validation-gen/...
    ```
*   **Run `validate/*` Logic Tests**:
    ```bash
    go test ./staging/src/k8s.io/apimachinery/pkg/api/validate/...
    ```
*   **Format Code**:
    ```bash
    hack/update-gofmt.sh
    ```
*   **Run All Verification Checks**:
    ```bash
    hack/verify-all.sh
    ```

## Learn More

* [Usage and Migration](/docs/code/declarative-validation/usage-and-migration/) - Learn how to use declarative validation for new APIs and how to migrate existing handwritten validation.
* [Validation Tags](/docs/code/declarative-validation/validation-tags/) - See the full catalog of available validation tags.
* [API Reviewers Guide](/docs/code/declarative-validation/api-reviewers-guide/) - Guidelines for API reviewers on reviewing PRs that use declarative validation.
