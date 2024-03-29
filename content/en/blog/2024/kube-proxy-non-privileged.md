---
layout: blog
title: "Kubernetes supports running kube-proxy in an unprivileged container"
date: 2024-01-05
slug: kube-proxy-non-privileged
author: Lars Ekman
---


This post describes how the `--init-only` flag to `kube-proxy` can be
used to run the main kube-proxy container in a stricter
`securityContext`, by performing the configuration that requires
privileged mode in a separate [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).
Since
Windows doesn't have the equivalent of `capabilities`, this only works
on Linux.

The `kube-proxy` Pod still only meets the *privileged* [Pod Security
Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/),
but there is still an improvement because the running container doesn't
need to run privileged.

Please note that `kube-proxy` can be installed in different ways. The
examples below assume that kube-proxy is run from a pod, but similar
changes could be made in clusters where it is run as a system service.


## Background

It is undesirable to run a server container like `kube-proxy` in
privileged mode. Security aware users wants to use capabilities instead.

If `kube-proxy` is installed as a POD, the initialization requires
"privileged" mode, mostly for setting sysctl's. However, `kube-proxy`
only tries to set the sysctl's if they don't already have the right
values. In theory, then, if a privileged [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
set the sysctls to the right values, then `kube-proxy` could run
unprivileged.

The problem is to know *what* to setup. Until now the only option has
been to read the source to see what changes `kube-proxy` would have
made, but with `--init-only` you can have `kube-proxy` itself do the setup
*exactly* as on a normal start, and then exit.


## Initializing kube-proxy in an init container

*The example manifests below are not complete, but narrowed down to what is
essential to illustrate the function.*

Usually, cluster operators run `kube-proxy` in a privileged security context.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    k8s-app: kube-proxy
spec:
  template:
    spec:
      containers:
      - name: kube-proxy
        command:
        - /usr/local/bin/kube-proxy
        - --config=/var/lib/kube-proxy/config.conf
        - --hostname-override=$(NODE_NAME)
        securityContext:
          privileged: true
   # (lots of stuff omitted here...)
```

But now it is possible to use:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    k8s-app: kube-proxy
spec:
  template:
    spec:
      initContainers:
      - name: kube-proxy-init
        command:
        - /usr/local/bin/kube-proxy
        - --config=/var/lib/kube-proxy/config.conf
        - --hostname-override=$(NODE_NAME)
        - --init-only
        securityContext:
          privileged: true
   # (lots of stuff omitted here...)
      containers:
      - name: kube-proxy
        command:
        - /usr/local/bin/kube-proxy
        - --config=/var/lib/kube-proxy/config.conf
        - --hostname-override=$(NODE_NAME)
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
   # (lots of stuff omitted here...)
```



## Summary

The `--init-only` flag can be used to perform privileged
initialization in an init container and run the main container with
`NET_ADMIN` capabilities only. Installers like `kubeadm` will likely be
altered to use this feature in the future.
