#!/usr/bin/env bash
# =============================================================================
# install_jenkins.sh — Fresh EC2 Ubuntu 22/24 LTS Jenkins Server Setup
# Installs: Java 21, Git, Maven 3.9.6, Docker, Jenkins (stable)
# Usage:  chmod +x install_jenkins.sh && ./install_jenkins.sh
# =============================================================================
set -euo pipefail

MVN_VERSION="3.9.6"
JENKINS_KEY_ID="7198F4B714ABFC68"
JAVA_HOME_PATH="/usr/lib/jvm/java-21-openjdk-amd64"

echo "========================================"
echo " [1/6] System update & upgrade"
echo "========================================"
sudo apt update && sudo apt upgrade -y

echo "========================================"
echo " [2/6] Java 21"
echo "========================================"
sudo apt install -y openjdk-21-jdk
java -version

echo "========================================"
echo " [3/6] Git"
echo "========================================"
sudo apt install -y git
git --version

echo "========================================"
echo " [4/6] Maven ${MVN_VERSION}"
echo "========================================"
sudo curl -fsSL \
  "https://archive.apache.org/dist/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz" \
  -o /tmp/maven.tar.gz
sudo tar -xzf /tmp/maven.tar.gz -C /opt/
sudo ln -sfn "/opt/apache-maven-${MVN_VERSION}" /opt/maven
sudo ln -sfn /opt/maven/bin/mvn /usr/local/bin/mvn
sudo rm -f /tmp/maven.tar.gz
mvn -version

echo "========================================"
echo " [5/6] Docker"
echo "========================================"
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

echo "========================================"
echo " [6/6] Jenkins (stable)"
echo "========================================"
# Install dependencies
sudo apt install -y curl gnupg2 dirmngr

# Clean any previous failed attempts
sudo rm -f /usr/share/keyrings/jenkins-keyring.gpg \
           /usr/share/keyrings/jenkins-keyring.asc \
           /etc/apt/sources.list.d/jenkins.list

# Required for gpg --keyserver to work
sudo mkdir -p /root/.gnupg
sudo chmod 700 /root/.gnupg

# Fetch the exact key that signs the Jenkins stable repo (port 80 avoids EC2 firewall blocks)
sudo gpg \
  --no-default-keyring \
  --keyring /usr/share/keyrings/jenkins-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys "${JENKINS_KEY_ID}"

# Add the stable repo
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
    https://pkg.jenkins.io/debian-stable binary/" \
    | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

# jenkins user now exists — add to docker group
sudo usermod -aG docker jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins

# Point Jenkins to Java 21 (no manual nano needed)
JENKINS_SERVICE="/lib/systemd/system/jenkins.service"
sudo sed -i \
  's|^#.*Environment="JAVA_HOME=.*"|Environment="JAVA_HOME='"${JAVA_HOME_PATH}"'"|' \
  "${JENKINS_SERVICE}"

sudo systemctl daemon-reload
sudo systemctl restart jenkins

echo ""
echo "========================================"
echo " All done! Verifying services..."
echo "========================================"
sudo systemctl status jenkins --no-pager
docker --version
mvn -version
java -version

echo ""
echo "============================================================"
echo "  Jenkins is ready!"
echo "  URL: http://$(curl -s http://<ip>/latest/meta-data/public-ipv4):8080"
echo ""
echo "  Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "============================================================"