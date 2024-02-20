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
    }
    
    // gradle 실행 권한 부여
    stages {
        stage('Gradle Wrapper에 실행 권한 부여') {
            steps {
                sh 'chmod +x ./gradlew'
            }
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
        
    stage('JAR 빌드') {
        steps {
            script {
                withEnv(['JAVA_HOME=/usr/lib/jvm/jdk-21.0.2']) {
                    sh './gradlew --version'
                    sh './gradlew clean build --warning-mode=none -x test --info'
                }
            }
        }
    }

    stage('Trivy 보안 검사') {
        steps {
            sh 'chmod +x trivy-image-scan.sh'
            sh './trivy-image-scan.sh'
        }
    }

    stage('Docker 이미지 빌드 및 ACR로 푸시') {
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
                    message: "ACR 푸시에 성공하였습니다."
                )
            }
            failure {
                slackSend (
                    channel: SLACK_CHANNEL,
                    color: SLACK_FAIL_COLOR,
                    message: "ACR 푸시에 실패하였습니다."
                )
            }
        }
    }

    stage('GitOps 체크아웃') {
        steps {
            git branch: 'main',
                credentialsId: 'jenkins-git-access',
                url: 'https://github.com/rlozi99/back-gitops'
        }
    }

    stage('Kubernetes 구성 업데이트') {
        steps {
            script {
                sh "kustomize edit set image ${CONTAINER_REGISTRY}/${REPO}=${CONTAINER_REGISTRY}/${REPO}:${TAG}"
                sh "git add ."
                sh "git commit -m '이미지 업데이트: ${TAG}'"
            }
        }
    }

    stage('GitOps 저장소에 변경사항 푸시') {
        steps {
            script {
                withCredentials([usernamePassword(credentialsId: "jenkins-git-access", passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    def currentBranch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    if (currentBranch != "main") {
                        sh "git checkout main"
                    }
                    sh "git pull --rebase origin main"
                    sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/rlozi99/back-gitops.git main"
                }
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
