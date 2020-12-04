# Setup Knative on Kind with Mink

Setup [Knative](https://knative.dev) on [Kind](https://kind.sigs.k8s.io/) with [Mink](https://github.com/mattmoor/mink)(Minimal Knative (min-K))


TLDR;
```bash
curl -sL mink.csantanapr.dev | bash
```

>Updated and verified on 2020/12/04 with:
>- Mink 0.19.0
>- Knative Serving 0.19.0
>- Knative Kourier 0.19.1
>- Knative Eventing 0.19.2
>- Kind version 0.9.0
>- Kubernetes version 1.19.4


## Install Docker for Desktop
To use kind, you will also need to [install docker](https://docs.docker.com/install/).

Verify that docker engine and CLI is working:
```
docker version
```


## Create cluster with Kind

Run the following command re-using the repository [knative-kind](https://github.com/csantanapr/knative-kind)
```bash
./01-kind.sh
```



## Install Mink CLI

More information about `mink` CLI read docs [CLI.md](https://github.com/mattmoor/mink/blob/master/CLI.md)

Check the latest version [released here](https://github.com/mattmoor/mink/releases)

For Linux or MacOS use the following, for Windows download directly from release page.
```bash
VERSION=0.19.0
TARBASE=mink_${VERSION}_$(uname -s)_$(uname -m)
curl -sL -O "https://github.com/mattmoor/mink/releases/download/v${VERSION}/${TARBASE}.tar.gz"
tar xzvf "${TARBASE}.tar.gz"
sudo mv "${TARBASE}/mink" /usr/local/bin/mink
rm -r "${TARBASE}"
rm "${TARBASE}.tar.gz"
```

## Install Knative with mink

1. Run the install command
    ```bash
    mink install
    ```
    The output should look like the following
    ```
    Cleaning up any old jobs.
    Installing mink core from: https://github.com/mattmoor/mink/releases/download/v0.19.0/core.yaml
    Waiting for mink core to be ready.
    Waiting for mink webhook to be ready.
    Installing in-memory channel from: https://github.com/mattmoor/mink/releases/download/v0.19.0/in-memory.yaml
    Waiting for in-memory channel to be ready.
    mink installation complete!
    ```
1. Configure Ingress to listen for http port 80 on localhost
    ```bash
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: mink-ingress
      namespace: mink-system
      labels:
        app: dataplane
        knative.dev/release: devel
    spec:
      type: NodePort
      selector:
        role: dataplane
      ports:
      - name: http2
        nodePort: 31080
        port: 80
        targetPort: 8080
    EOF
    ```
1. Set the environment variable `EXTERNAL_IP` to External IP Address of the Worker Node
    ```bash
    EXTERNAL_IP="127.0.0.1"
    ```
1. Set the environment variable `KNATIVE_DOMAIN` as the DNS domain using `nip.io`
    ```bash
    KNATIVE_DOMAIN="$EXTERNAL_IP.nip.io"
    echo KNATIVE_DOMAIN=$KNATIVE_DOMAIN
    ```
    Double-check DNS is resolving
    ```bash
    dig $KNATIVE_DOMAIN
    ```
1. Configure DNS for Knative Serving
    ```bash
    kubectl patch configmap -n mink-system config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"
    ```
1. Verify that Knative is Installed properly all pods should be in `Running` state and our `kourier-ingress` service configured.
    ```bash
    kubectl get pods,svc -n mink-system
    ```