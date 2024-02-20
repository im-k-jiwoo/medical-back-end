pipeline {
    agent any

    environment {
        // Azure 정보
        AZURE_SUBSCRIPTION_ID = 'c8ce3edc-0522-48a3-b7e4-afe8e3d731d9'
        AZURE_TENANT_ID = '4ccd6048-181f-43a0-ba5a-7f48e8a4fa35'
        CONTAINER_REGISTRY = 'goodbirdacr.azurecr.io'
        RESOURCE_GROUP = 'AKS'
        REPO = 'medical/back'
        IMAGE_NAME = 'medical/back:latest'

        // 태그
        TAG_VERSION = "v1.0.Beta"
        TAG = "${TAG_VERSION}${env.BUILD_ID}"
        NAMESPACE = 'back'

        // Slack 알림
        SLACK_CHANNEL = "#jenkins-build-alert"
        SLACK_SUCCESS_COLOR = "#2C953C";
        SLACK_FAIL_COLOR = "#FF3232";

        // GitOps
        GIT_CREDENTIALS_ID = 'jenkins-git-access'
        JAR_FILE_PATH = 'build/libs/demo-0.0.1-SNAPSHOT.jar'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Grant Execute Permission to Gradle Wrapper') {
            steps {
                sh 'chmod +x ./gradlew'
            }
        }

        stage('Build JAR') {
            steps {
                script {
                    withEnv(['JAVA_HOME=/usr/lib/jvm/jdk-21.0.2']) {
                        sh './gradlew --version'
                        sh './gradlew clean build --warning-mode=none -x test --info'
                    }
                }
            }
        }

        stage('Trivy Security') {
            steps {
                sh 'chmod +x trivy-image-scan.sh'
                sh './trivy-image-scan.sh'
            }
        }

        stage('Build and Push Docker Image to ACR') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'acr-credential-id', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USERNAME')]) {
                        sh "az acr login --name $CONTAINER_REGISTRY --username $ACR_USERNAME --password $ACR_PASSWORD"
                        sh "docker build -t $REPO:$TAG ."
                        sh "docker tag $REPO:$TAG $CONTAINER_REGISTRY/$REPO:$TAG"
                        sh "docker push $CONTAINER_REGISTRY/$REPO:$TAG"
                    }
                }
            }
            post {
                success {
                    slackSend (
                        channel: SLACK_CHANNEL,
                        color: SLACK_SUCCESS_COLOR,
                        message: "ACR Push에 성공하였습니다."
                    )
                }
                failure {
                    slackSend (
                        channel: SLACK_CHANNEL,
                        color: SLACK_FAIL_COLOR,
                        message: "ACR Push에 실패하였습니다."
                    )
                }
            }
        }

        stage('Push Changes to GitOps Repository') {
            steps {
                script {
                    // 원하는 작업 수행
                    echo "Changes pushed to GitOps Repository"
                }
            }
            post {
                success {
                    slackSend (
                        channel: SLACK_CHANNEL,
                        color: SLACK_SUCCESS_COLOR,
                        message: "배포에 성공하였습니다."
                    )
                }
                failure {
                    slackSend (
                        channel: SLACK_CHANNEL,
                        color: SLACK_FAIL_COLOR,
                        message: "배포에 실패하였습니다."
                    )
                }
            }
        }
    }
}
