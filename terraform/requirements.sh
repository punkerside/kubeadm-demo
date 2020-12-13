#!/bin/bash

systemctl stop apparmor
systemctl disable apparmor

echo "apparmor desactivado" >> /tmp//k8s.log

export OS=xUbuntu_20.04
export VERSION=1.19

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

echo "so configurado" >> /tmp//k8s.log

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -

apt-get -y update
apt-get -y install cri-o cri-o-runc

systemctl daemon-reload
systemctl start crio
systemctl enable crio

echo "crio instalado" >> /tmp//k8s.log

apt-get install -y apt-transport-https

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "kubelet kubeadm kubectl instalados" >> /tmp//k8s.log

sed -i 's|--kubeconfig=/etc/kubernetes/kubelet.conf|--kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=systemd|g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "kubeadm configurado" >> /tmp//k8s.log
