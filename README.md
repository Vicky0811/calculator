# Java Calculator — Complete CI/CD Pipeline
### Git → Maven → Docker → Kubernetes → Jenkins

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Java | 21 |
| Frontend | JSP | — |
| Web Server | Embedded Tomcat | 10.1.18 |
| Packaging | Fat JAR (Maven Shade) | — |
| Build Tool | Maven | 3.9.6 |
| Testing | JUnit 5 | 5.10.0 |
| Container | Docker | latest |
| Orchestration | Kubernetes (kubeadm) | 1.29 |
| CI/CD | Jenkins (Pipeline) | 2.x |
| IaC | Terraform | — |
| Version Control | Git + GitHub | — |
| Image Registry | DockerHub | — |

---

## Architecture

```
Local Machine
    │  git push
    ▼
GitHub → webhook → Jenkins EC2
                        │
                        ├── 1. mvn clean compile
                        ├── 2. mvn test
                        ├── 3. mvn package → calculator.jar
                        ├── 4. docker build → image
                        ├── 5. docker push → DockerHub
                        └── 6. kubectl apply → K8s cluster
                                    │
                              K8s Master EC2
                                    │  schedules pods
                              K8s Worker EC2
                                    │
                              http://<NODE-IP>:30080 ✅
```

---

## Infrastructure

| Server | Name | Public IP | Private IP | Instance Type |
|---|---|---|---|---|
| Jenkins    | `jenkins-server` |  | t3.small |
| K8s Master | `Cal-K8S-Master` |  | c7i-flex.large |
| K8s Worker | `Cal-K8S-Worker` |  | c7i-flex.large |

---

## Project Structure

```
java-calculator/
├── src/
│   ├── main/
│   │   ├── java/com/calculator/
│   │   │   ├── Calculator.java          # Core math logic
│   │   │   ├── CalculatorServlet.java   # Handles POST requests
│   │   │   └── Main.java               # Boots embedded Tomcat
│   │   └── webapp/
│   │       ├── index.jsp               # JSP frontend
│   │       └── WEB-INF/
│   │           └── web.xml             # Servlet mapping
│   └── test/
│       └── java/com/calculator/
│           └── CalculatorTest.java     # JUnit 5 tests
├── k8s/
│   ├── deployment.yaml                 # K8s Deployment
│   └── service.yaml                    # K8s NodePort Service
├── Dockerfile                          # Multi-stage Docker build
├── Jenkinsfile                         # Pipeline script from SCM
├── pom.xml                             # Maven build config
└── .gitignore
```

---

## PART 1 — INFRASTRUCTURE (Terraform)

### STEP 1 — main.tf

```hcl
provider "aws" {
    profile = "${var.profile}"
    region  = "${var.region}"
}

resource "aws_instance" "Jenkins-server" {
    ami                    = "${var.amis}"
    instance_type          = "t3.small"
    tags                   = { Name = "Jenkins-server" }
    key_name               = "project-arovm"
    vpc_security_group_ids = ["sg-03041bf59a541bfef"]
}

resource "aws_instance" "K8S_master" {
    ami                    = "${var.amis}"
    instance_type          = "c7i-flex.large"
    tags                   = { Name = "Cal-K8S-Master" }
    key_name               = "project-arovm"
    vpc_security_group_ids = ["sg-0d0d16ea201f54d62"]
}

resource "aws_instance" "K8S_Worker" {
    ami                    = "${var.amis}"
    instance_type          = "c7i-flex.large"
    tags                   = { Name = "Cal-K8S-Worker" }
    key_name               = "project-arovm"
    vpc_security_group_ids = ["sg-0d0d16ea201f54d62"]
}

output "jenkins_ip" { value = aws_instance.Jenkins-server.public_ip }
output "master_ip"  { value = aws_instance.K8S_master.public_ip }
output "worker_ip"  { value = aws_instance.K8S_Worker.public_ip }
```

### STEP 2 — Apply

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

### STEP 3 — Get Private IPs (Windows PowerShell)

```powershell
ssh -i C:\Users\parma\Downloads\project-arovm.pem ubuntu@IP1 "hostname -I"
ssh -i C:\Users\parma\Downloads\project-arovm.pem ubuntu@IP2 "hostname -I"
ssh -i C:\Users\parma\Downloads\project-arovm.pem ubuntu@IP3 "hostname -I"
```

---

## PART 2 — SECURITY GROUP RULES

### Jenkins Server
| Port | Source | Purpose |
|------|--------|---------|
| 22 | Your IP | SSH |
| 8080 | 0.0.0.0/0 | Jenkins UI + GitHub webhook |

### K8s Master
| Port | Source | Purpose |
|------|--------|---------|
| 22 | Your IP | SSH |
| 6443 | Jenkins Private IP | kubectl API |
| 6443 | Worker Private IP | K8s API |
| 10250 | Worker Private IP | Kubelet |
| 2379-2380 | Master Private IP | etcd |
| 30000-32767 | Your IP | NodePort App |

### K8s Worker
| Port | Source | Purpose |
|------|--------|---------|
| 22 | Your IP | SSH |
| 10250 | Master Private IP | Kubelet |
| 30000-32767 | Your IP | NodePort App |

---

## PART 3 — JENKINS SERVER SETUP

### STEP 4 — Run install_jenkins.sh

```bash
ssh -i project-arovm.pem ubuntu@44.202.100.0
```

```bash
#!/usr/bin/env bash
set -euo pipefail

MVN_VERSION="3.9.6"
JENKINS_KEY_ID="7198F4B714ABFC68"
JAVA_HOME_PATH="/usr/lib/jvm/java-21-openjdk-amd64"

echo "=== [1/6] System update ==="
sudo apt update && sudo apt upgrade -y

echo "=== [2/6] Java 21 ==="
sudo apt install -y openjdk-21-jdk
java -version

echo "=== [3/6] Git ==="
sudo apt install -y git
git --version

echo "=== [4/6] Maven ${MVN_VERSION} ==="
sudo curl -fsSL \
  "https://archive.apache.org/dist/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz" \
  -o /tmp/maven.tar.gz
sudo tar -xzf /tmp/maven.tar.gz -C /opt/
sudo ln -sfn "/opt/apache-maven-${MVN_VERSION}" /opt/maven
sudo ln -sfn /opt/maven/bin/mvn /usr/local/bin/mvn
sudo rm -f /tmp/maven.tar.gz
mvn -version

echo "=== [5/6] Docker ==="
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

echo "=== [6/6] Jenkins ==="
sudo apt install -y curl gnupg2 dirmngr
sudo rm -f /usr/share/keyrings/jenkins-keyring.gpg \
           /etc/apt/sources.list.d/jenkins.list
sudo mkdir -p /root/.gnupg && sudo chmod 700 /root/.gnupg

sudo gpg \
  --no-default-keyring \
  --keyring /usr/share/keyrings/jenkins-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys "${JENKINS_KEY_ID}"

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
    | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins
sudo usermod -aG docker jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Point Jenkins to Java 21
sudo sed -i \
  's|^#.*Environment="JAVA_HOME=.*"|Environment="JAVA_HOME='"${JAVA_HOME_PATH}"'"|' \
  /lib/systemd/system/jenkins.service

sudo systemctl daemon-reload
sudo systemctl restart jenkins

echo "Jenkins URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

```bash
chmod +x install_jenkins.sh && ./install_jenkins.sh
```

---

## PART 4 — K8s NODES SETUP

### STEP 5 — Run install_k8s_node.sh on Master AND Worker

```bash
# Master
ssh -i project-arovm.pem ubuntu@54.161.237.28

# Worker
ssh -i project-arovm.pem ubuntu@44.204.46.96
```

Run on **both**:

```bash
cat > install_k8s_node.sh << 'SCRIPT'
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

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "=== [6/6] Verify ==="
docker --version
kubeadm version
kubectl version --client
echo "=== Node ready! ==="
SCRIPT

chmod +x install_k8s_node.sh && ./install_k8s_node.sh
```

---

## PART 5 — INITIALISE KUBERNETES CLUSTER

### STEP 6 — Init on Master Only

```bash
ssh -i project-arovm.pem ubuntu@54.161.237.28

sudo kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --apiserver-advertise-address=172.31.84.247
```

Copy the `kubeadm join` command from output.

### STEP 7 — Configure kubectl on Master

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

kubectl get nodes
```

### STEP 8 — Join Worker

```bash
ssh -i project-arovm.pem ubuntu@44.204.46.96

sudo kubeadm join 172.31.84.247:6443 \
    --token xxxx \
    --discovery-token-ca-cert-hash sha256:xxxx
```

Verify on Master:

```bash
kubectl get nodes
# Cal-K8S-Master   Ready   control-plane
# Cal-K8S-Worker   Ready   <none>
```

---

## PART 6 — CONFIGURE JENKINS FOR K8s

### STEP 9 — Install kubectl on Jenkins

```bash
ssh -i project-arovm.pem ubuntu@44.202.100.0

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
    | sudo gpg --dearmor \
    -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update && sudo apt install -y kubectl
kubectl version --client
```

### STEP 10 — Copy kubeconfig to Jenkins

On **Master**:
```bash
cat ~/.kube/config   # copy entire output
```

On **Jenkins**:
```bash
sudo mkdir -p /var/lib/jenkins/.kube
sudo nano /var/lib/jenkins/.kube/config
# paste → Ctrl+O → Enter → Ctrl+X

sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chmod 600 /var/lib/jenkins/.kube/config

# Test
sudo -u jenkins kubectl get nodes   # both nodes Ready ✅
```

---

## PART 7 — JENKINS UI SETUP

### STEP 11 — Unlock Jenkins

1. Open `http://44.202.100.0:8080`
2. `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Paste → **Install suggested plugins** → create admin user

### STEP 12 — Install Extra Plugins

**Manage Jenkins → Plugins → Available plugins**

- `Maven Integration`
- `SSH Agent`
- `Docker Pipeline`

Restart when done.

### STEP 13 — Configure Global Tools

**Manage Jenkins → Tools**

```
JDK:
  Name:      JDK-21
  JAVA_HOME: /usr/lib/jvm/java-21-openjdk-amd64

Maven:
  Name:                  Maven-3.9
  Install automatically: ✅
  Version:               3.9.6
```

Click **Save**

### STEP 14 — Add Credentials

**Manage Jenkins → Credentials → Global → Add Credentials**

```
GitHub:
  Kind:     Username with password
  ID:       github-creds
  Username: GitHub username
  Password: GitHub Personal Access Token

DockerHub:
  Kind:     Username with password
  ID:       dockerhub-creds
  Username: DockerHub username
  Password: DockerHub access token
```

### STEP 15 — Create Pipeline Job

1. **Dashboard → New Item → java-calculator → Pipeline → OK**

```
General:
  ☑ Discard old builds → Max 5

Build Triggers:
  ☑ GitHub hook trigger for GITScm polling

Pipeline:
  Definition:   Pipeline script from SCM
  SCM:          Git
  URL:          https://github.com/Vicky0811/java-calculator-k8s.git
  Credentials:  github-creds
  Branch:       */main
  Script Path:  Jenkinsfile
```

Click **Save**

### STEP 16 — Add GitHub Webhook

GitHub repo → **Settings → Webhooks → Add webhook**

```
Payload URL:  http://44.202.100.0:8080/github-webhook/
Content type: application/json
Events:       Just the push event ✅
```

---

## PART 8 — RUN PIPELINE

### STEP 17 — Push Code

```bash
cd java-calculator
git init
git add .
git commit -m "feat: Java calculator — Docker + K8s + Jenkins"
git remote add origin https://github.com/Vicky0811/java-calculator-k8s.git
git branch -M main
git push -u origin main
```

### STEP 18 — Build Now

**Dashboard → java-calculator → Build Now**

```
Checkout      ✅
Build         ✅
Test          ✅
Package       ✅
Docker Build  ✅
Docker Push   ✅  → DockerHub
Deploy to K8s ✅  → kubectl apply
Verify        ✅  → 2/2 pods running
Finished: SUCCESS
```

### STEP 19 — Open App

```
http://54.161.237.28:30080/   ← Master
http://44.204.46.96:30080/    ← Worker
```

### STEP 20 — Test Auto Trigger

```bash
git add . && git commit -m "test: auto trigger" && git push origin main
# Jenkins triggers instantly via webhook ✅
```

---

## Useful Commands

```bash
# Kubernetes
kubectl get all                                         # all resources
kubectl get nodes                                       # node status
kubectl get pods -o wide                                # pod locations
kubectl logs <POD_NAME>                                 # pod logs
kubectl describe pod <POD_NAME>                         # debug
kubectl scale deployment java-calculator --replicas=3   # scale
kubectl rollout undo deployment/java-calculator         # rollback
kubectl delete -f k8s/                                  # delete all

# Docker
docker ps                    # running containers
docker images                # local images

# Jenkins
sudo systemctl status jenkins    # check
sudo systemctl restart jenkins   # restart
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Jenkins GPG key error | Use `gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7198F4B714ABFC68` |
| K8s repo malformed entry | Use single line echo — no backslash continuation |
| Nodes NotReady | Wait 2-3 min, check Flannel: `kubectl get pods -n kube-system` |
| Jenkins kubectl fails | Copy kubeconfig to `/var/lib/jenkins/.kube/config` |
| Docker permission denied | `sudo usermod -aG docker jenkins` + restart Jenkins |
| Pods Pending | Check resources: `kubectl describe pod <name>` |
| Image pull error | Check dockerhub-creds ID matches Jenkinsfile |
| Webhook not triggering | Port 8080 open to `0.0.0.0/0` in security group |
| Test reports not found | Use `**/surefire-reports/*.xml` |
| Spring Boot test error | Delete `CalculatorApplicationTests.java` from repo |

---

## Pipeline Flow Summary

```
git push
    ↓ webhook
Jenkins
    ↓ mvn compile → mvn test → mvn package
    ↓ docker build → docker push (DockerHub :BUILD_NUMBER + :latest)
    ↓ kubectl apply → rolling update
K8s Cluster
    ↓ 2 pods running (1 on Master, 1 on Worker)
http://<NODE-IP>:30080 ✅
```
