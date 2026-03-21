# Java Calculator — CI/CD Pipeline
### Git → Maven → Jenkins (Freestyle) → Two EC2 Servers (Ubuntu)

---

## Architecture

```
Local Machine
     │
     │  git push
     ▼
  GitHub
     │
     │  polls every 5 min
     ▼
EC2 #1 — Jenkins Server (t3.small)
  Ubuntu 22.04
  Java 21, Maven 3.9, Git, Jenkins :8080
     │
     │  scp JAR + ssh commands
     ▼
EC2 #2 — App Server (t2.micro)
  Ubuntu 22.04
  Java 21 only
  calculator.jar :8080
     │
     ▼
http://<APP-IP>:8080  ✅
```

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
├── pom.xml                             # Maven build config
└── .gitignore
```

---

## PART 1 — LOCAL MACHINE

### STEP 1 — Install Git

```bash
# Check
git --version

# Install if missing
sudo apt install -y git          # Ubuntu/Linux
xcode-select --install           # Mac
# Windows → https://git-scm.com
```

### STEP 2 — Create Project Structure

```bash
mkdir java-calculator
cd java-calculator

mkdir -p src/main/java/com/calculator
mkdir -p src/main/webapp/WEB-INF
mkdir -p src/test/java/com/calculator
```

Copy all source files into the correct locations as shown in the project structure above.

### STEP 3 — Push to GitHub

```bash
cd java-calculator

git init
git add .
git commit -m "feat: JSP calculator with embedded Tomcat"

# Create repo on github.com first, then:
git remote add origin https://github.com/<YOUR_USERNAME>/java-calculator.git
git branch -M main
git push -u origin main
```

> **Note:** Check your default branch name on GitHub (main or master) and use that consistently.

---

## PART 2 — AWS — LAUNCH TWO EC2 INSTANCES

### STEP 4 — Launch Jenkins EC2 (Server 1)

1. **AWS Console → EC2 → Launch Instance**

   | Setting       | Value                                   |
   |---------------|-----------------------------------------|
   | Name          | `jenkins-server`                        |
   | AMI           | Ubuntu 22.04 LTS                        |
   | Instance type | `t3.small` (2 GB RAM minimum)           |
   | Key pair      | Create new → download → save as `mykey.pem` |

2. Security Group inbound rules:

   | Port | Source  | Purpose    |
   |------|---------|------------|
   | 22   | Your IP | SSH        |
   | 8080 | Your IP | Jenkins UI |

3. Click **Launch Instance**

### STEP 5 — Launch App EC2 (Server 2)

1. **AWS Console → EC2 → Launch Instance**

   | Setting       | Value                              |
   |---------------|------------------------------------|
   | Name          | `app-server`                       |
   | AMI           | Ubuntu 22.04 LTS                   |
   | Instance type | `t2.micro`                         |
   | Key pair      | **Select same `mykey.pem`**        |

2. Security Group inbound rules:

   | Port | Source                  | Purpose                    |
   |------|-------------------------|----------------------------|
   | 22   | Your IP                 | SSH from your machine      |
   | 22   | Jenkins EC2 Private IP  | SSH from Jenkins to deploy |
   | 8080 | Your IP                 | Calculator App             |

3. Click **Launch Instance**

> After both launch, note down:
> - Jenkins EC2 Public IP
> - App EC2 Public IP
> - App EC2 **Private IP** (used for Jenkins → App communication)

---

## PART 3 — SETUP JENKINS SERVER (EC2 #1)

### STEP 6 — SSH into Jenkins Server

```bash
chmod 400 mykey.pem
ssh -i mykey.pem ubuntu@<JENKINS_EC2_PUBLIC_IP>
```

### STEP 7 — Install Java 21, Maven, Git, Jenkins

```bash
# Update
sudo apt update && sudo apt upgrade -y

# Java 21
sudo apt install -y openjdk-21-jdk
java -version

# Git
sudo apt install -y git
git --version

# Maven 3.9
MVN_VERSION="3.9.6"
sudo curl -fsSL \
  https://archive.apache.org/dist/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz \
  -o /tmp/maven.tar.gz
sudo tar -xzf /tmp/maven.tar.gz -C /opt/
sudo ln -sfn /opt/apache-maven-${MVN_VERSION} /opt/maven
sudo ln -sfn /opt/maven/bin/mvn /usr/local/bin/mvn
mvn -version

# Jenkins
sudo apt install -y curl gnupg2
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
    | sudo gpg --dearmor \
    | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
    https://pkg.jenkins.io/debian-stable binary/" \
    | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins   # should say: active (running)
```

### STEP 8 — Point Jenkins to Java 21

```bash
# Open Jenkins service file
sudo nano /lib/systemd/system/jenkins.service

# Search for JAVA_HOME (Ctrl+W → type JAVA_HOME → Enter)
# Find this line:
#Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"

# Remove the # to uncomment:
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"

# Save: Ctrl+O → Enter → Ctrl+X
```

```bash
# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart jenkins

# Verify Java 21
sudo -u jenkins java -version
# should show: openjdk version "21.x.x"
```

### STEP 9 — Generate SSH Key for Jenkins User

```bash
sudo mkdir -p /var/lib/jenkins/.ssh

sudo ssh-keygen -t rsa -b 4096 \
    -f /var/lib/jenkins/.ssh/id_rsa \
    -N ""

sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh
sudo chmod 600 /var/lib/jenkins/.ssh/id_rsa

# Print public key — COPY THIS OUTPUT
sudo cat /var/lib/jenkins/.ssh/id_rsa.pub
```

---

## PART 4 — SETUP APP SERVER (EC2 #2)

### STEP 10 — SSH into App Server

Open a **new terminal** on your local machine:

```bash
ssh -i mykey.pem ubuntu@<APP_EC2_PUBLIC_IP>
```

### STEP 11 — Install Java 21 Only

```bash
sudo apt update
sudo apt install -y openjdk-21-jdk
java -version

# Create app directory
sudo mkdir -p /opt/calculator
sudo chown ubuntu:ubuntu /opt/calculator
```

### STEP 12 — Add Jenkins Public Key

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

nano ~/.ssh/authorized_keys
# Paste the Jenkins public key from STEP 9
# Save: Ctrl+O → Enter → Ctrl+X

chmod 600 ~/.ssh/authorized_keys
exit
```

### STEP 13 — Test SSH Connection

Back on **Jenkins EC2**:

```bash
sudo -u jenkins ssh -o StrictHostKeyChecking=no \
    ubuntu@<APP_EC2_PRIVATE_IP>

# Should connect without password prompt ✅
exit
```

---

## PART 5 — JENKINS UI SETUP

### STEP 14 — Unlock Jenkins

1. Open browser → `http://<JENKINS_EC2_PUBLIC_IP>:8080`
2. Get password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

3. Paste → **Continue**
4. Click **"Install suggested plugins"** → wait
5. Create admin user → **Save and Finish**

### STEP 15 — Install Extra Plugins

**Manage Jenkins → Plugins → Available plugins**

Search and install:
- `Maven Integration`
- `SSH Agent`

Check **"Restart Jenkins when done"** → log back in

### STEP 16 — Configure Global Tools

**Manage Jenkins → Tools**

#### Find JAVA_HOME on Jenkins EC2:
```bash
sudo -u jenkins java -XshowSettings:property -version 2>&1 | grep java.home
# output: java.home = /usr/lib/jvm/java-21-openjdk-amd64
```

#### JDK Section:
```
Add JDK
Name:      JDK-21
JAVA_HOME: /usr/lib/jvm/java-21-openjdk-amd64
```

#### Maven Section:
```
Add Maven
Name:                  Maven-3.9
Install automatically: ✅ checked
Install from Apache
Version:               3.9.6
```

Click **Save**

### STEP 17 — Add SSH Credential for App Server

```bash
# Get Jenkins private key
sudo cat /var/lib/jenkins/.ssh/id_rsa
# Copy entire output including BEGIN and END lines
```

**Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

```
Kind:        SSH Username with private key
ID:          app-ec2-ssh-key
Description: App Server SSH Key
Username:    ubuntu
Private Key: Enter directly → paste entire id_rsa content
```

Click **Create**

---

## PART 6 — CREATE JENKINS JOB

### STEP 18 — Create Freestyle Job

1. **Dashboard → New Item**
2. Name: `java-calculator`
3. Select **Freestyle project** → **OK**

### STEP 19 — General Tab

```
Description:         Java Calculator — JSP + Embedded Tomcat
☑ Discard old builds
  Max # of builds:   5
```

### STEP 20 — Source Code Management Tab

```
● Git
Repository URL:  https://github.com/<YOU>/java-calculator.git

Credentials → Add → Jenkins
  Kind:     Username with password
  Username: your GitHub username
  Password: your GitHub Personal Access Token
  → click Add → select from dropdown

Branch Specifier:  */main   (or */master — match your repo)
```

### STEP 21 — Build Triggers Tab

```
☑ Poll SCM
  Schedule:  H/5 * * * *
```

### STEP 22 — Build Environment Tab

```
☑ SSH Agent
  Credentials: app-ec2-ssh-key
```

### STEP 23 — Build Steps Tab

#### Step 1 → Invoke top-level Maven targets
```
Maven Version: Maven-3.9
Goals:         clean compile
```

#### Step 2 → Invoke top-level Maven targets
```
Maven Version: Maven-3.9
Goals:         test
```

#### Step 3 → Invoke top-level Maven targets
```
Maven Version: Maven-3.9
Goals:         package -DskipTests
```

#### Step 4 → Execute shell
```bash
#!/bin/bash
set -e

APP_USER="ubuntu"
APP_IP="<APP_EC2_PRIVATE_IP>"       # ← replace with real Private IP
DEPLOY_DIR="/opt/calculator"
JAR="calculator.jar"

echo "=== Copying JAR to App Server ==="
scp -o StrictHostKeyChecking=no \
    target/${JAR} \
    ${APP_USER}@${APP_IP}:${DEPLOY_DIR}/${JAR}

echo "=== Stopping old process ==="
ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} \
    "pkill -f ${JAR} || true"

echo "=== Waiting for process to stop ==="
ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} \
    "sleep 2"

echo "=== Starting new version ==="
ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} \
    "nohup java -jar ${DEPLOY_DIR}/${JAR} > ${DEPLOY_DIR}/app.log 2>&1 &"

echo "=== Verifying app started ==="
ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} \
    "sleep 4 && pgrep -f ${JAR} && echo 'App is running ✅' || echo 'App failed to start ❌'"

echo "=== Deployment complete ==="
```

### STEP 24 — Post-build Actions Tab

#### Action 1 → Publish JUnit test result report
```
Test report XMLs:  **/surefire-reports/*.xml
```

#### Action 2 → Archive the artifacts
```
Files to archive:  target/calculator.jar
```

Click **Save**

---

## PART 7 — RUN AND VERIFY

### STEP 25 — Build Now

1. **Dashboard → java-calculator → Build Now**
2. Click **#1 → Console Output**

Expected output:
```
[INFO] BUILD SUCCESS                  ← compile
[INFO] Tests run: 16, Failures: 0    ← test
[INFO] Building jar: calculator.jar  ← package
=== Copying JAR to App Server ===
=== Stopping old process ===
=== Waiting for process to stop ===
=== Starting new version ===
=== Verifying app started ===
App is running ✅
=== Deployment complete ===
Finished: SUCCESS
```

### STEP 26 — Open the App

```
http://<APP_EC2_PUBLIC_IP>:8080/
```

### STEP 27 — Verify on App Server

```bash
ssh -i mykey.pem ubuntu@<APP_EC2_PUBLIC_IP>

pgrep -a -f calculator.jar       # check process
tail -f /opt/calculator/app.log  # check logs
```

### STEP 28 — Test Auto Trigger

```bash
# Make any change locally then:
git add .
git commit -m "test: auto trigger pipeline"
git push origin main

# Jenkins detects change within 5 minutes
# Auto runs: compile → test → package → deploy ✅
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Couldn't find any revision to build` | Branch name wrong — check `*/main` vs `*/master` |
| `Permission denied (publickey)` on SCP | Jenkins public key not added to App server `~/.ssh/authorized_keys` |
| Wrong IP in shell script | Use App EC2 **Private IP**, not Jenkins IP |
| `package org.springframework.boot does not exist` | Delete `CalculatorApplicationTests.java` — it's a Spring Boot file not needed here |
| Test reports not found | Use `**/surefire-reports/*.xml` pattern |
| `CalculatorTest.java` not found by Maven | File must be at `src/test/java/com/calculator/CalculatorTest.java` |
| Jenkins Java 17 end of life warning | Uncomment `JAVA_HOME` line in `/lib/systemd/system/jenkins.service` pointing to Java 21 |
| Jenkins GPG key error on apt update | Use `gpg --dearmor` method to add Jenkins keyring |
| App not starting on App server | Check `/opt/calculator/app.log` for errors |

---

## Pipeline Summary

```
Developer writes code
        │
        ▼  git push
    GitHub repo
        │
        ▼  polls every 5 min
  Jenkins (EC2 #1)
        │
        ├── mvn clean compile    Step 1 — compile
        ├── mvn test             Step 2 — run 16 JUnit tests
        ├── mvn package          Step 3 — build calculator.jar
        └── Execute Shell        Step 4 — deploy
              │
              ├── scp JAR → App EC2
              ├── ssh pkill old process
              ├── ssh nohup java -jar (start new)
              └── ssh pgrep (verify running)
                        │
                        ▼
               App Server (EC2 #2)
               http://<APP-IP>:8080 ✅
```

---

## Technology Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Java | 21 |
| Frontend | JSP + HTML/CSS | — |
| Web Server | Embedded Tomcat | 10.1.18 |
| Packaging | Fat JAR (Maven Shade) | — |
| Build Tool | Maven | 3.9.6 |
| Testing | JUnit 5 | 5.10.0 |
| Version Control | Git + GitHub | — |
| CI/CD | Jenkins Freestyle | 2.x |
| Jenkins Host | AWS EC2 Ubuntu | t3.small |
| App Host | AWS EC2 Ubuntu | t2.micro |
