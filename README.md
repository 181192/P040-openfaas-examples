# OpenFaaS examples

> This guide requires [docker](https://docs.docker.com/install/), [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [faas-cli](https://github.com/openfaas/faas-cli#get-started-install-the-cli) and [k3d](https://github.com/rancher/k3d#get) to be installed.
> Steps on how to install `k3d` and `faas-cli` are provided in this guide.

## TL;DR

Requires `docker`, `kubectl`, `faas-cli` and `k3d`.

See next step on how to install `k3d` and `faas-cli`.

```
./setup.sh
```

## Install `k3d` and `faas-cli`

Install k3d's cli that is a little helper to run [Rancher Lab's k3s in Docker](https://github.com/rancher/k3d).

[k3s](https://github.com/rancher/k3s) is a lightweight Kubernetes distribution, 5 times less than k8s.

```
curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | TAG=v1.3.2 bash
```

Install `faas-cli`.

```sh
curl -sSL https://cli.openfaas.com | sudo sh
```

## Create cluster

Create a cluster with 3 workers and expose a NodePort on worker-0 at 8080.

```
k3d create --publish 8080:8080@k3d-k3s-default-worker-0 --workers 3
```

## Install OpenFaaS

### 1.0 Create namespaces

```sh
kubectl apply -f namespaces.yml
```

### 2.0 Create password

Generate secrets so that we can enable basic authentication for the gateway:

```sh
kubectl -n openfaas create secret generic basic-auth \
--from-literal=basic-auth-user=admin \
--from-literal=basic-auth-password=admin
```

For better security generate a random password

```sh
# generate a random password
PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)

kubectl -n openfaas create secret generic basic-auth \
--from-literal=basic-auth-user=admin \
--from-literal=basic-auth-password="$PASSWORD"
```

### 3.0 Apply YAML files

```sh
kubectl apply -f ./setup/
```

### 4.0 Log in

Now log-in:

```sh
faas login --password admin

# or

echo -n $PASSWORD | faas-cli login --password-stdin

```

List the current functions deployed

```
faas list

Function                        Invocations     Replicas
```

## Deploying a demo function

Build the function

```
faas build -f ./hello-python.yml
```

You can check the image by listing the docker images

```
docker images | grep hello-python
```

Import the local docker image from our local docker daemon into the cluster

```
k3d i hello-python:latest
# or
k3d import-images hello-python:latest
```

Deploy the function

```
faas deploy -f hello-python.yml
```

List the functions

```
faas list
```

Test the function

```
curl 127.0.0.1:8080/function/hello-python -d "Demo"
```

## Creating my first function

OpenFaas provides a lot of premade templates:

```
template/
├── csharp
├── csharp-armhf
├── dockerfile
├── dockerfile-armhf
├── go
├── go-armhf
├── java12
├── java8
├── node
├── node-arm64
├── node-armhf
├── php7
├── python
├── python3
├── python3-armhf
├── python-armhf
└── ruby
```

For instance to create a nodejs function simply run

```
faas-cli new myfirst --lang node
```

Repeat the previous section on how to deploy it, here's an example of a nodejs handler function:

```javascript
module.exports = (context, callback) => {
  callback(undefined, { status: 'done' })
}
```
