pipeline {
    agent any
    environment {
        DOCKER_HUB_REPO = "ashirhs/study-buddy-ai"
        DOCKER_HUB_CREDENTIALS_ID = "dockerhub-token"
        IMAGE_TAG = "v${BUILD_NUMBER}"
    }
    stages {
        stage('Checkout Github') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-token', url: 'https://github.com/ashirsyed/study-buddy-ai.git']])
            }
        }        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    dockerImage = docker.build("${DOCKER_HUB_REPO}:${IMAGE_TAG}")
                }
            }
        }
        stage('Push Image to DockerHub') {
            steps {
                script {
                    echo 'Pushing Docker image to DockerHub...'
                    docker.withRegistry('https://registry.hub.docker.com' , "${DOCKER_HUB_CREDENTIALS_ID}") {
                        dockerImage.push("${IMAGE_TAG}")
                    }
                }
            }
        }
        stage('Update Deployment YAML with New Tag') {
            steps {
                script {
                    sh """
                    sed -i 's|image: ashirhs/study-buddy-ai:.*|image: ashirhs/study-buddy-ai:${IMAGE_TAG}|' manifests/deployment.yaml
                    """
                }
            }
        }

        stage('Commit Updated YAML') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh '''
                        git config user.name "ashirsyed"
                        git config user.email "your-email@example.com"
                        git add manifests/deployment.yaml
                        git commit -m "Update image tag to ${IMAGE_TAG}" || echo "No changes to commit"
                        git push https://${GIT_USER}:${GIT_PASS}@github.com/ashirsyed/study-buddy-ai.git HEAD:main
                        '''
                    }
                }
            }
        }
        stage('Install Kubectl & ArgoCD CLI Setup') {
            steps {
                sh '''
                echo 'installing Kubectl & ArgoCD cli...'
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl
                mv kubectl /usr/local/bin/kubectl
                curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                chmod +x /usr/local/bin/argocd
                '''
            }
        }
        stage('Apply Kubernetes & Sync App with ArgoCD') {
            steps {
                script {
                    kubeconfig(credentialsId: 'kubeconfig', serverUrl: 'https://kubernetes.default.svc') {
                        sh '''
                        # Port forward ArgoCD (background)
                        kubectl port-forward svc/argocd-server -n argocd 8080:443 &
                        sleep 5
                        argocd login localhost:8080 --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --insecure || echo "ArgoCD login failed"
                        argocd app sync study-buddy-ai || echo "ArgoCD sync failed, check connection"
                        '''
                    }
                }
            }
        }
    }
}