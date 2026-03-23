pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
        jdk   'JDK-21'
    }

    environment {
        DOCKERHUB_USER = 'vickydocks'
        IMAGE_NAME     = "${DOCKERHUB_USER}/java-calculator"
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo '=== Pulling latest code ==='
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo '=== Compiling ==='
                sh 'mvn clean compile -B'
            }
        }

        stage('Test') {
            steps {
                echo '=== Running tests ==='
                sh 'mvn test -B'
            }
            post {
                always {
                    junit '**/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                echo '=== Packaging JAR ==='
                sh 'mvn package -DskipTests -B'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/calculator.jar',
                                     fingerprint: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo '=== Building Docker image ==='
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Docker Push') {
            steps {
                echo '=== Pushing to DockerHub ==='
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login \
                            -u \$DOCKER_USER --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                        docker logout
                    """
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                echo '=== Deploying to Kubernetes ==='
                sh """
                    sed -i 's|${IMAGE_NAME}:.*|${IMAGE_NAME}:${IMAGE_TAG}|g' \
                        k8s/deployment.yaml
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout status deployment/java-calculator \
                        --timeout=120s
                """
            }
        }

        stage('Verify') {
            steps {
                echo '=== Verifying deployment ==='
                sh """
                    echo '--- Nodes ---'
                    kubectl get nodes
                    echo '--- Pods ---'
                    kubectl get pods -o wide
                    echo '--- Service ---'
                    kubectl get svc java-calculator-svc
                    echo '--- Deployment ---'
                    kubectl get deployment java-calculator
                """
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline complete — App live on Kubernetes!'
        }
        failure {
            echo '❌ Pipeline failed — check the red stage.'
        }
    }
}