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
                script {
                    echo 'Checking out code from GitHub...'
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: '*/main']],
                            userRemoteConfigs: [[
                                url: "https://${GITHUB_TOKEN}@github.com/ashirsyed/study-buddy-ai.git"
                            ]]
                        ])
                    }
                }
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
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                        git config user.name "ashirsyed"
                        git config user.email "your-email@example.com"
                        git add manifests/deployment.yaml
                        git commit -m "Update image tag to ${IMAGE_TAG}" || echo "No changes to commit"
                        git push https://${GITHUB_TOKEN}@github.com/ashirsyed/study-buddy-ai.git HEAD:main
                        '''
                    }
                }
            }
        }
        stage('Install Kubectl & ArgoCD CLI Setup') {
            steps {
                sh '''
                echo 'Installing Kubectl & ArgoCD CLI...'
                
                # Create bin directory in workspace (writable by Jenkins)
                mkdir -p ${WORKSPACE}/bin
                export PATH=${WORKSPACE}/bin:$PATH
                
                # Install kubectl
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl
                mv kubectl ${WORKSPACE}/bin/kubectl
                
                # Install ArgoCD CLI
                curl -sSL -o ${WORKSPACE}/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                chmod +x ${WORKSPACE}/bin/argocd
                
                # Verify installations
                kubectl version --client
                argocd version --client
                '''
            }
        }
        stage('Apply Kubernetes & Sync App with ArgoCD') {
            steps {
                script {
                    kubeconfig(credentialsId: 'kubeconfig', serverUrl: 'https://kubernetes.default.svc') {
                        sh '''
                        # Add bin directory to PATH
                        export PATH=${WORKSPACE}/bin:$PATH
                        
                        # Verify kubectl and argocd are available
                        which kubectl || echo "kubectl not found in PATH"
                        which argocd || echo "argocd not found in PATH"
                        
                        # Port forward ArgoCD (background)
                        kubectl port-forward svc/argocd-server -n argocd 8080:443 &
                        sleep 5
                        
                        # Login to ArgoCD
                        argocd login localhost:8080 --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --insecure || echo "ArgoCD login failed"
                        
                        # Sync application
                        argocd app sync study-buddy-ai || echo "ArgoCD sync failed, check connection"
                        '''
                    }
                }
            }
        }
    }
}