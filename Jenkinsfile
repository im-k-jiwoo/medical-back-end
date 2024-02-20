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

        // 체크섬 검사
        stages {
                stage('Checkout') {
                    steps {
                        checkout scm
                    }
                }

        // gradle 실행 권한 부여
        stage('Grant Execute Permission to Gradle Wrapper') {
                    steps {
                        sh 'chmod +x ./gradlew'
                    }
                }

        
        // JAR 파일 빌드 단계 추가
        stage('Build JAR') {
            steps {
                script {
                    withEnv(['JAVA_HOME=/usr/lib/jvm/jdk-21.0.2']) {
                        // Gradle을 사용하여 JAR 파일 빌드
                        sh './gradlew --version'
                        sh './gradlew clean build --warning-mode=none -x test --info'
                    }
                }
            }
        }

        stage('Trivy Security') {
              steps {
                  sh 'chmod +x trivy-image-scan.sh' // 스크립트에 실행 권한 추가
                  sh './trivy-image-scan.sh' // Trivy 이미지 스캔 실행
              }
        }

        stage('Build and Push Docker Image to ACR') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'acr-credential-id', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USERNAME')]) {
                        // Log in to ACR
                        sh "az acr login --name $CONTAINER_REGISTRY --username $ACR_USERNAME --password $ACR_PASSWORD"
                        // Dockerfile에 있는 JAR 파일을 사용하여 Docker 이미지 빌드
                        sh "docker build -t $REPO:$TAG ."
                        // 이미지 태그 지정 및 ACR로 푸시
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
