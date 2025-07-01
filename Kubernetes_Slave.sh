#!/bin/bash
set -e

# Step 1: Basic Packages
dnf update -y
sudo dnf install -y curl --allowerasing

# Step 2: Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Step 3: Load kernel modules
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

modprobe br_netfilter
modprobe overlay

# Step 4: Sysctl settings
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Step 5: Install containerd
dnf install -y containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd

# Step 6: Add Kubernetes repo
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

# Step 7: Install Kubernetes components
dnf install -y kubelet kubeadm kubectl
systemctl enable --now kubelet


echo "✅ Kubernetes v1.31 cluster setup complete on Amazon Linux 2023!"
