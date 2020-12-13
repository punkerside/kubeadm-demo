#!/bin/bash

kubeadm init --control-plane-endpoint "kubeadm-demo-440106bcc66645ba.elb.us-east-1.amazonaws.com:6443" --upload-certs

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
