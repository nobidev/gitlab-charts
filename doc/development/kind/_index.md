---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Developing for Kubernetes with KinD
---

This guide is meant to serve as a cross-platform resource for setting up a local Kubernetes development environment.
In this guide, we'll be using [KinD](https://kind.sigs.k8s.io). It creates a Kubernetes cluster using Docker, and provides easy mechanisms for deploying different versions as well as multiple nodes.

We will also make use of [nip.io](https://nip.io), which lets us map any IP address to a hostname using a format like this: `192.168.1.250.nip.io`, which maps to `192.168.1.250`. No installation is required.

{{< alert type="note" >}}

With the SSL-enabled installation options below, if you want to clone repositories and push changes, you will have to do so over HTTPS instead of SSH. We are planning to address this with an update to GitLab Shell's service exposure via NodePorts.

{{< /alert >}}

## Apple silicon (M1/M2)

`kind` can be used with [`colima`](https://github.com/abiosoft/colima) to provide a local Kubernetes development environment on macOS, including `M1` and `M2` variants.

### Installing dependencies

- Make sure that you're running MacOS >= 13 (Ventura).
- Install [`colima`](https://github.com/abiosoft/colima#installation).
- Install [`Rosetta`](https://support.apple.com/en-us/102527):

  ```shell
  softwareupdate --install-rosetta
  ```

### Building the VM

Create the `colima` VM:

```shell
colima start --cpu 6 --memory 16 --disk 40 --profile docker --arch aarch64 --vm-type=vz --vz-rosetta
```

When ready, you can follow the [preparation](#preparation) below to install GitLab with `kind`.

### Managing the VM

To stop the `colima` VM:

```shell
colima stop --profile docker
```

To start again the VM:

```shell
colima start --profile docker
```

To remove and clean up the local system:

```shell
colima delete --profile docker
```

## Preparation

### Required information

All of the following installation options require knowing your host IP. Here are a couple options to find this information:

- Linux: `hostname -i`
- MacOS: `ipconfig getifaddr en0`

{{< alert type="note" >}}

Most MacOS systems use `en0` as the primary interface. If using a system with a different primary interface, please substitute that interface name for `en0`.

{{< /alert >}}

### Using namespaces

It is considered best practice to install applications in namespaces other than `default`. Create a namespace **prior** to running `helm install` with **kubectl**:

```shell
kubectl create namespace YOUR_NAMESPACE
```

Add `--namespace YOUR_NAMESPACE` to all future **kubectl** commands to use the namespace. Alternatively, use `kubens` from the [kubectx project](https://github.com/ahmetb/kubectx) to contextually switch into the namespace and skip the extra typing.

### Installing dependencies

You can use `asdf` ([more info](../environment_setup.md#additional-developer-tools)) to install the following tools:

- `kubectl`
- `helm`
- `kind`

Note that `kind` uses Docker to run local Kubernetes clusters, so be sure to [install Docker](https://docs.docker.com/get-docker/).

### Obtaining configuration examples

The GitLab charts repository contains every example referenced in the following steps. Clone the repository or update an existing checkout to get the latest versions:

```shell
git clone https://gitlab.com/gitlab-org/charts/gitlab.git
```

### Spin up the Kind cluster

There are a few example configurations in `doc/examples/kind` pending your desires and needs for testing.
Please review these configurations and make adjustments as necessary.
You can now spin up the cluster. Example:

```shell
kind create cluster --config examples/kind/kind-ssl.yaml
```

### Adding GitLab Helm chart

Follow these commands to set up your system to access the GitLab Helm charts:

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
```

## Deployment options

Select from one of the following deployment options based on your needs.

{{< alert type="note" >}}

The first full deployment process may take around 10 minutes depending on network and system resources while the cloud-native GitLab images are downloaded. Confirm GitLab is running with the following command:

{{< /alert >}}

```shell
kubectl --namespace YOUR_NAMESPACE get pods
```

GitLab is fully deployed when the `webservice` pod shows a `READY` state with `2/2` containers.

### NGINX Ingress NodePort with SSL

In this method, we will use `kind` to expose the NGINX controller service's NodePorts to ports on your local machine with SSL enabled.

```shell
kind create cluster --config examples/kind/kind-ssl.yaml
helm upgrade --install gitlab gitlab/gitlab \
  --set global.hosts.domain=(your host IP).nip.io \
  -f examples/kind/values-base.yaml \
  -f examples/kind/values-ssl.yaml
```

You can then access GitLab at `https://gitlab.(your host IP).nip.io`.

#### (Optional) Add root CA

In order for your browser to trust our self-signed certificate, download the root CA and trust it:

```shell
kubectl get secret gitlab-wildcard-tls-ca -ojsonpath='{.data.cfssl_ca}' | base64 --decode > gitlab.(your host IP).nip.io.ca.pem
```

Now that the root CA is downloaded, you can add it to your local chain (instructions vary per platform and are readily available online).

{{< alert type="note" >}}

If you need to log into the registry with `docker login`, you will need to take additional steps to configure the registry to work with your self-signed certificates. More instructions can be found in:

{{< /alert >}}

- [Run an externally-accessible registry](https://distribution.github.io/distribution/about/deploying/#run-an-externally-accessible-registry)
- [Adding self-signed registry certificates to Docker and Docker for macOS](https://blog.container-solutions.com/adding-self-signed-registry-certs-docker-mac).

### NGINX Ingress NodePort without SSL

In this method, we will use `kind` to expose the NGINX controller service's NodePorts to ports on your local machine with SSL disabled.

```shell
kind create cluster --config examples/kind/kind-no-ssl.yaml
helm upgrade --install gitlab gitlab/gitlab \
  --set global.hosts.domain=(your host IP).nip.io \
  -f examples/kind/values-base.yaml \
  -f examples/kind/values-no-ssl.yaml
```

Access GitLab at `http://gitlab.(your host IP).nip.io`.

{{< alert type="note" >}}

If you need to log into the registry with `docker login`, you will need to tell Docker to [trust your insecure registry](https://distribution.github.io/distribution/about/insecure/#deploy-a-plain-http-registry).

{{< /alert >}}

### Handling DNS

This guide assumes you have network access to [nip.io](https://nip.io). If this is not available to you, please refer to the [handling DNS](../minikube/_index.md#handling-dns) section in the minikube documentation which will also work for KinD.

{{< alert type="note" >}}

When editing **/etc/hosts**, remember to use the [host computer's IP address](#required-information) rather than the output of `$(minikube ip)`.

{{< /alert >}}

## Cleaning up

When you're ready to clean up your local system, run this command:

```shell
kind delete cluster
```

{{< alert type="note" >}}

If you named your cluster upon creation, or if you are running multiple clusters, you can delete specific ones with the `--name` flag.

{{< /alert >}}

## Troubleshooting and Edge cases

If you followed the steps above and you can't access your deployment on `http(s)://gitlab.(your host IP).nip.io` on MacOS there might be some issues with colima's network interface binding on `en0`.
You can try one of the following:

### Change DNS server to `8.8.8.8`(Google) or `1.1.1.1`(Cloudflare)

{{< alert type="note" >}}

If using `curl -vk "http(s)://gitlab.(your host IP).nip.io:(80/443)"` resolves to `(your host IP)` you can probably skip this, it is most-likely not DNS related.

{{< /alert >}}

There are 2 ways you can approach this, start by adding the DNS Servers to the `colima` config:

- `colima template` (to open the colima config file in your default editor)
  - find the `network:` block
    - update `dns:` to `["1.1.1.1", "8.8.8.8"]`
- `colima delete --profile docker`
- continue with [preparation](#preparation)

If that does not work either try one of the steps below or add the DNS servers to your MacBook Network settings.
(Steps on how to update your DNS config can be found online)

### Set colima `network.mode` to `bridged`

- Ensure `en0` is the primary network interface on the machine
- `colima template` (to open the colima config file in your default editor)
  - Find the `network:` block
    - Update `mode:` to `bridged`
    - Update `interface:` to your primary network interface (default is `en0`)
- `colima delete --profile docker`
- Continue with [preparation](#preparation)

### Use `--network-address` when starting a Docker VM with `colima`

- Perform a Cleanup:
  - `kind delete cluster` (use `--name` if a name was specified upon creating the cluster)
  - `colima delete --profile docker`
- Create a colima Docker VM with the `network.address` set to `true`
  - `colima start --cpu 6 --memory 16 --disk 40 --profile docker --arch aarch64 --vm-type=vz --vz-rosetta --network-address`
- Get the address set by colima to use as `your host IP`
  - `colima status --profile docker` -> copy the `address:` field value to use as (your host IP) for the `helm` command
- Continue following the desired [Deployment Options](#deployment-options)
- Check if you can access the deployment on `http://gitlab.(your colima address).nip.io` or `https://gitlab.(your colima address).nip.io`
