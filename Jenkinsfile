pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
        jdk   'jdk-21'
    }

    environment {
        APP_USER   = 'ubuntu'
        APP_IP     = '172.31.30.224'
        DEPLOY_DIR = '/opt/calculator'
        JAR        = 'calculator.jar'
    }

    stages {

        stage('Checkout') {
            steps {
                echo '=== Pulling code from GitHub ==='
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo '=== Compiling source code ==='
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                echo '=== Running JUnit tests ==='
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                echo '=== Packaging fat JAR ==='
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/calculator.jar',
                                     fingerprint: true
                }
            }
        }

        stage('Deploy') {
            steps {
                echo '=== Deploying to App Server ==='
                sshagent(['app-ec2-ssh-key']) {
                    sh """
                        echo '--- Copying JAR ---'
                        scp -o StrictHostKeyChecking=no \\
                            target/${JAR} \\
                            ${APP_USER}@${APP_IP}:${DEPLOY_DIR}/${JAR}

                        echo '--- Stopping old process ---'
                        ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} \\
                            "kill \$(pgrep -f ${JAR}) 2>/dev/null || true; sleep 2"

                        echo '--- Starting new version ---'
                        ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} \\
                            "nohup java -jar ${DEPLOY_DIR}/${JAR} > ${DEPLOY_DIR}/app.log 2>&1 &"
                    """
                }
            }
        }

        stage('Verify') {
            steps {
                echo '=== Verifying app is running ==='
                sshagent(['app-ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${APP_USER}@${APP_IP} \\
                            "sleep 4 && pgrep -f ${JAR} && echo 'App is running ✅' || (echo 'App failed ❌' && exit 1)"
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed — App deployed successfully!'
        }
        failure {
            echo '❌ Pipeline failed — check the stage that went red.'
        }
    }
}