#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

APP_IMAGE=$(read_input "Enter the app image" "gitlab.cs.pub.ro:5050/scgc/cloud-courses/hello-app:1.0")
NGINX_IMAGE=$(read_input "Enter the NGINX image" "gitlab.cs.pub.ro:5050/scgc/cloud-courses/nginx:latest")
HELLO_APP_PORT=$(read_input "Enter the port for hello-app" "8080")
HELLO_APP_NODE_PORT=$(read_input "Enter the node port for hello-app" "30080")
NGINX_NODE_PORT=$(read_input "Enter the node port for NGINX" "30888")
NGINX_INDEX_CONTENT=$(read_input "Enter the content for NGINX index.html" "<html><body>Hello from SCGC Lab!</body></html>")

kind create cluster

kubectl cluster-info

cat <<EOF > hello-app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  labels:
    app: hello
spec:
  replicas: 10
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello-app
        image: $APP_IMAGE
        ports:
        - containerPort: $HELLO_APP_PORT
EOF

kubectl apply -f hello-app-deployment.yaml

cat <<EOF > hello-app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-app
spec:
  type: NodePort
  selector:
    app: hello
  ports:
    - protocol: TCP
      port: $HELLO_APP_PORT
      targetPort: $HELLO_APP_PORT
      nodePort: $HELLO_APP_NODE_PORT
EOF

kubectl apply -f hello-app-service.yaml

cat <<EOF > nginx-html.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html
data:
  index.html: |
    $NGINX_INDEX_CONTENT
EOF

kubectl apply -f nginx-html.yaml

cat <<EOF > nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: $NGINX_IMAGE
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-html-vol
          mountPath: "/usr/share/nginx/html/index.html"
          subPath: "index.html"
        - name: nginx-conf-vol
          mountPath: "/etc/nginx/conf.d/default.conf"
          subPath: "default.conf"
      volumes:
      - name: nginx-html-vol
        configMap:
          name: nginx-html
          items:
          - key: "index.html"
            path: "index.html"
      - name: nginx-conf-vol
        configMap:
          name: nginx-conf
          items:
          - key: "default.conf"
            path: "default.conf"
EOF

kubectl apply -f nginx-deployment.yaml

cat <<EOF > nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: $NGINX_NODE_PORT
EOF

kubectl apply -f nginx-service.yaml

cat <<EOF > nginx-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
data:
  default.conf: |
    server {
      listen       80;
      server_name  localhost;

      location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
      }

      location /hello {
        proxy_pass http://hello-app:$HELLO_APP_PORT;
      }
    }
EOF

kubectl apply -f nginx-config.yaml

NODE_IP=$(kubectl describe nodes kind-control-plane | grep InternalIP | awk '{print $2}')

echo "Testing NGINX root:"
curl http://$NODE_IP:$NGINX_NODE_PORT

echo "Testing NGINX /hello proxy:"
curl http://$NODE_IP:$NGINX_NODE_PORT/hello