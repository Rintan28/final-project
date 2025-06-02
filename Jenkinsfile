pipeline {
    agent any

    environment {
        IMAGE_NAME = 'kelompok3/devops-final-project'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir() // bersihkan workspace dulu
                git url: 'https://github.com/Rintan28/final-project.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    sh "docker build -t $IMAGE_NAME:$IMAGE_TAG ."
                }
            }
        }

        stage('Run Docker Container (Local Dev)') {
            steps {
                echo '🚀 Running container locally (optional for test)...'
                script {
                    sh "docker run -d -p 8080:80 --name devops-final-container $IMAGE_NAME:$IMAGE_TAG"
                }
            }
        }

        // Optional: You can add a stage to push image to DockerHub if needed
        /*
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    sh "docker push $IMAGE_NAME:$IMAGE_TAG"
                }
            }
        }
        */
    }
    
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    sh "docker push $IMAGE_NAME:$IMAGE_TAG"
                }
            }
        }


    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'docker stop devops-final-container || true'
            sh 'docker rm devops-final-container || true'
        }
    }
}
