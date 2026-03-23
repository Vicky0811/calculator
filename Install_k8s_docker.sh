#Run On worker and master of k8s nodes

#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/6] Update ==="
sudo apt update && sudo apt upgrade -y

echo "=== [2/6] Docker ==="
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << 'DOCKEREOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
DOCKEREOF
sudo systemctl restart docker
docker --version

echo "=== [3/6] Disable swap ==="
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "=== [4/6] Kernel modules ==="
sudo tee /etc/modules-load.d/k8s.conf > /dev/null << 'MODEOF'
overlay
br_netfilter
MODEOF
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/k8s.conf > /dev/null << 'SYSCTLEOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTLEOF
sudo sysctl --system

echo "=== [5/6] kubeadm kubelet kubectl ==="
sudo apt install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
    | sudo gpg --dearmor \
    -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "=== [6/6] Verify ==="
docker --version
kubeadm version
kubectl version --client
echo ""
echo "========================================"
echo " Node ready for K8s!"
echo "========================================"