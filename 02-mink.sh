#!/usr/bin/env bash

set -eo pipefail
set -u
INGRESS_HOST="127.0.0.1"
KNATIVE_DOMAIN=$INGRESS_HOST.nip.io

mink install
kubectl -n mink-system patch cm config-leader-election --type merge -p '{"data":{"buckets":"1"}}'
kubectl -n mink-system scale statefulset/controlplane --replicas 1
kubectl -n mink-system rollout restart statefulset/controlplane

kubectl patch configmap -n mink-system config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"

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

cat <<EOF | kubectl apply -f -
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
        - image: gcr.io/knative-samples/helloworld-go
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "Knative"
EOF
kubectl wait ksvc hello --all --timeout=-1s --for=condition=Ready
SERVICE_URL=$(kubectl get ksvc hello -o jsonpath='{.status.url}')
echo "The SERVICE_ULR is $SERVICE_URL"
curl $SERVICE_URL