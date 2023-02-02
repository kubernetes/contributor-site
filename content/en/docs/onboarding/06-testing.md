---
title: "Section 6: Testing"
type: reveal
weight: 6
description: |
    Learn about the different types of tests in the Kubernetes project and how to run them.
---

# Section 6: Testing

This unit is all about the various types of tests, both automated and manual, in the Kubernetes project. 

---

# What you're about to learn

By the time you're done with this unit, you'll:

* Be able to locate the requirements for manual testing during development
* Be able to respond to the automatic tests of bots for a pull request

Testing Kubernetes is pretty complicated. We will try to make it easy for you, but you might want to start by reading the [Development Guide](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md).

---

# What are the different types of tests?

In the course of developing Kubernetes, you will interact with three different test types:

1. Unit tests
2. Integration tests
3. End-to-End tests

Let's learn about each type of test!

---

# Unit tests

**Unit tests** run against the smallest possible components of code, like an individual function or API calls.

* Contributions with new significant functionality **must** come with unit tests!
* Unit tests can use mock clients and servers to emulate aspects of the Kubernetes API for testing.

---

# Integration tests

**Integration tests** make sure that components work together flawlessly as a group.

* All significant features require integration tests—including kubectl commands.
* Integration tests are able to test the behavior of the Kubernetes API _without_ bringing up a whole cluster.
* This makes integration tests more realistic than unit tests.

---

# End-to-End tests

**End-to-end (E2E) tests** emulate an entire execution path across the entire application, from start to end.

* E2E tests are the last signal to ensure end user operations match developer specifications.
* Significant features **should** come with e2e tests.
  * If you contribute a new feature without e2e tests, be prepared to explain your reasoning to your PR's reviewers.

---

# Who is responsible for Kubernetes tests?

*"Developers! Developers! Developers!" — Steve Ballmer*

* Any contributor adding new functionality will be responsible for creating tests that validate their contribution.
* Any contributor submitting a pull request will be responsible for making sure that tests run against their contribution—and pass!
* [SIG Testing](https://github.com/kubernetes/community/tree/master/contributors/devel/sig-testing) is responsible for maintaining the test framework.

---

# What is presubmission verification?

Presubmission is the phase before a pull request is created—the steps that you, the contributor, can take to maximize your PR's chance of success.

* Presubmission verification is a collection of checks that give your pull request the best chance of being accepted.
* Developers need to run as many verification tests as possible locally.
* [Learn how to run them in the Development Guide.](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#presubmission-verification)

---

# How do I interact with unit tests?

Pull requests need to pass **all** unit tests.

* Run them all from your development directory with `make test`
* You can also run unit tests individually during the development process.
* [Read everything there is to know about unit tests in the Testing Guide.](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/testing.md#unit-tests)

---

# How do I interact with integration tests?

Pull requests also need to pass **all** integration tests.

* If you are testing locally, you might need to install extra software.
* These tests are run from your development environment with `make test-integration`
* [Read Integration Testing in Kubernetes to learn more about this type of test.](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/integration-tests.md)

---

# How do I interact with end-to-end (E2E) tests?

E2E tests build test binaries, spin up a test cluster, run the tests, and then tear the cluster down.

- **Note: Running all E2E tests takes a very long time!**

You will not need to run E2E tests for every pull request. [The End-to-End Testing Guide is a great place to learn more.](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/e2e-tests.md)

---

# How does testing affect my pull request?

You should run tests locally or in your development environment before submitting a pull request, because it will speed up the process.

* The bots that process pull requests will run tests against your code!
* When the tests fail, your pull request will stall.
* You will need to use the **/ok-to-test** command to tell the bot to run tests again.

[Read about the ok-to-test label in the Pull Request Process documentation.](/docs/guide/pull-requests/#more-about-ok-to-test)

---

# Testing Resources

We've covered a lot of ground in this unit, and if you want to go deeper, here is a collection of all the resources we used.

* [SIG Testing documentation](https://github.com/kubernetes/community/tree/master/contributors/devel/sig-testing)
* [The Development Guide](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#presubmission-verification)
* [The Testing Guide](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/testing.md#unit-tests)
* [Integration Testing in Kubernetes](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/integration-tests.md)
* [End-to-End Testing Guide](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-testing/e2e-tests.md)
* [Pull Request documentation](/docs/guide/pull-requests/#more-about-ok-to-test)

<div class="bottom-nav">
    <a href="/docs/onboarding">Onboarding Index</a> | <a href="../07-code-review/">Next Section</a>
</div>
