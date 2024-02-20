
pipeline {
    agent any

    environment {
        // Azure 정보
        AZURE_SUBSCRIPTION_ID = 'c8ce3edc-0522-48a3-b7e4-afe8e3d731d9'
        AZURE_TENANT_ID = '4ccd6048-181f-43a0-ba5a-7f48e8a4fa35'
        CONTAINER_REGISTRY = 'goodbirdacr.azurecr.io'
        RESOURCE_GROUP = 'AKS'

         // 태그
        REPO = 'medical/back'
        IMAGE_NAME = 'medical/back:latest'
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

        // stage('SonarQube Analysis') {
        //     steps {
        //         script {
        //             def scannerHome = tool 'sonarqube_scanner'
        //             withSonarQubeEnv('SonarQubeServer') {
        //                 // SonarScanner 실행 명령에 -X 옵션 추가
        //                 sh "${scannerHome}/bin/sonar-scanner -X"
        //             }
        //         }
        //     }
        // }
        
        // JAR 파일 빌드 단계 추가
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
        
        // stage('SonarQube Analysis') {
        //             steps {
        //                 withSonarQubeEnv('SonarQubeServer') {
        //                     script {
        //                         // SonarQube 스캔 명령어 실행
        //                         sh "./gradlew sonar clean build --warning-mode=none -x test --info"
        //                     }
        //                 }
        //             }
        //         }

        // stage('Trivy Security') {
        //     steps {
        //         sh 'chmod +x trivy-image-scan.sh'
        //         sh './trivy-image-scan.sh'
        //     }
        // }

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


        
        stage('Checkout GitOps') {
                    steps {
                        // 'front_gitops' 저장소에서 파일들을 체크아웃합니다.
                        git branch: 'main',
                            credentialsId: 'jenkins-git-access',
                            url: 'https://github.com/rlozi99/back-gitops'
                    }
                }
        stage('Update Kubernetes Configuration') {
                    steps {
                        script {
                            // kustomize를 사용하여 Kubernetes 구성 업데이트
                            // dir('gitops') 블록을 제거합니다.
                            sh "kustomize edit set image ${CONTAINER_REGISTRY}/${REPO}=${CONTAINER_REGISTRY}/${REPO}:${TAG}"
                            sh "git add ."
                            sh "git commit -m 'Update image to ${TAG}'"
                        }
                    }
                }

        stage('Push Changes to GitOps Repository') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "jenkins-git-access", passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                        // 현재 브랜치 확인 및 main으로 체크아웃
                        def currentBranch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                        if (currentBranch != "main") {
                            sh "git checkout main"
                        }
                        // 원격 저장소에서 최신 변경사항 가져오기
                        sh "git pull --rebase origin main"
                        def remote = "https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/JoEunSae/back-end.git"
                        // 원격 저장소에 푸시
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
}
