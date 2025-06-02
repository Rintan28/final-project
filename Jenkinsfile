pipeline {
    agent {
        docker {
            image 'node:18'
        }
    
    environment {
        DOCKER_REGISTRY = 'your-registry'
        K8S_NAMESPACE = 'final-project'
        APP_NAME = 'static-website'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Rintan28/final-project.git'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm install -g html-validate'
                sh 'html-validate src/*.html'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}")
                    docker.withRegistry('', 'docker-hub-credentials') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                        sed -i 's|IMAGE_TAG|${BUILD_NUMBER}|g' k8s/deployment.yaml
                        kubectl apply -f k8s/ -n ${K8S_NAMESPACE}
                        kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline berhasil! Website sudah di-deploy.'
        }
        failure {
            echo 'Pipeline gagal! Check logs untuk troubleshooting.'
        }
    }
}
