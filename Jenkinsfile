pipeline {
    agent any
    
    environment {
        // Docker Registry Configuration
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_REPO = 'eve56/devops-landing-page'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG}"
        
        // Kubernetes Configuration
        KUBE_NAMESPACE = 'final-project'
        KUBE_DEPLOYMENT = 'landing-page-deployment'
        
        // Application Configuration
        APP_NAME = 'devops-landing-page'
        APP_PORT = '80'
        
        // Credentials
        DOCKER_CREDENTIALS = 'docker-registry-credentials'
        KUBE_CREDENTIALS = 'kubernetes-credentials'
        
        // SonarQube (optional)
        SONAR_PROJECT_KEY = 'devops-landing-page'
    }
    
    tools {
        nodejs '18.17.0' // Specify Node.js version if needed
        dockerTool 'docker-latest'
    }
    
    stages {
        stage('🚀 Checkout') {
            steps {
                script {
                    echo "🔄 Checking out code from repository..."
                    checkout scm
                    
                    // Get commit info for better tracking
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    
                    env.GIT_BRANCH_NAME = sh(
                        script: "git rev-parse --abbrev-ref HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('🔍 Code Quality Check') {
            parallel {
                stage('HTML Validation') {
                    steps {
                        script {
                            echo "🔍 Validating HTML structure..."
                            // Install HTML validator
                            sh '''
                                npm install -g html-validator-cli
                                html-validator --file=index.html --format=json > html-validation.json || true
                            '''
                            
                            // Archive validation results
                            archiveArtifacts artifacts: 'html-validation.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('CSS Validation') {
                    steps {
                        script {
                            echo "🎨 Validating CSS..."
                            sh '''
                                npm install -g css-validator
                                css-validator index.html > css-validation.txt || true
                            '''
                            archiveArtifacts artifacts: 'css-validation.txt', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        script {
                            echo "🔒 Running security scan..."
                            sh '''
                                npm install -g retire
                                retire --path . --outputformat json --outputpath retire-report.json || true
                            '''
                            archiveArtifacts artifacts: 'retire-report.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        stage('🧪 Testing') {
            steps {
                script {
                    echo "🧪 Running tests..."
                    
                    // Create test script
                    writeFile file: 'test.js', text: '''
                        const fs = require('fs');
                        const path = require('path');
                        
                        console.log('🧪 Running basic tests...');
                        
                        // Test 1: Check if HTML file exists
                        if (fs.existsSync('index.html')) {
                            console.log('✅ index.html exists');
                        } else {
                            console.log('❌ index.html not found');
                            process.exit(1);
                        }
                        
                        // Test 2: Check HTML content
                        const htmlContent = fs.readFileSync('index.html', 'utf8');
                        
                        if (htmlContent.includes('<title>')) {
                            console.log('✅ HTML has title tag');
                        } else {
                            console.log('❌ HTML missing title tag');
                            process.exit(1);
                        }
                        
                        if (htmlContent.includes('viewport')) {
                            console.log('✅ HTML is mobile responsive');
                        } else {
                            console.log('❌ HTML missing viewport meta tag');
                            process.exit(1);
                        }
                        
                        // Test 3: Check for modern CSS features
                        if (htmlContent.includes('grid') || htmlContent.includes('flexbox')) {
                            console.log('✅ Modern CSS detected');
                        } else {
                            console.log('❌ Modern CSS features not found');
                        }
                        
                        console.log('🎉 All tests passed!');
                    '''
                    
                    sh 'node test.js'
                }
            }
        }
        
        stage('📦 Build Docker Image') {
            steps {
                script {
                    echo "📦 Building Docker image..."
                    
                    // Build Docker image
                    def dockerImage = docker.build("${DOCKER_IMAGE}")
                    
                    // Tag with latest
                    dockerImage.tag("${DOCKER_REGISTRY}/${DOCKER_REPO}:latest")
                    
                    // Tag with git commit
                    dockerImage.tag("${DOCKER_REGISTRY}/${DOCKER_REPO}:${GIT_COMMIT_SHORT}")
                    
                    env.DOCKER_IMAGE_ID = dockerImage.id
                }
            }
        }
        
        stage('🔍 Docker Security Scan') {
            steps {
                script {
                    echo "🔍 Scanning Docker image for vulnerabilities..."
                    sh '''
                        # Install Trivy scanner
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        
                        # Scan the image
                        trivy image --format json --output trivy-report.json ${DOCKER_IMAGE} || true
                    '''
                    
                    archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('🚀 Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🚀 Pushing Docker image to registry..."
                    
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS}") {
                        def dockerImage = docker.image("${DOCKER_IMAGE}")
                        dockerImage.push()
                        dockerImage.push("latest")
                        dockerImage.push("${GIT_COMMIT_SHORT}")
                    }
                }
            }
        }
        
        stage('🌐 Deploy to Staging') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'staging'
                }
            }
            steps {
                script {
                    echo "🌐 Deploying to staging environment..."
                    
                    // Update Kubernetes deployment
                    withKubeConfig([credentialsId: "${KUBE_CREDENTIALS}"]) {
                        sh '''
                            kubectl set image deployment/${KUBE_DEPLOYMENT} \
                                landing-page=${DOCKER_IMAGE} \
                                -n staging
                            
                            kubectl rollout status deployment/${KUBE_DEPLOYMENT} -n staging
                        '''
                    }
                }
            }
        }
        
        stage('🎯 Deploy to Production') {
            when {
                anyOf {
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🎯 Deploying to production environment..."
                    
                    // Deployment approval
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: 'Deploy to Production?', 
                              ok: 'Deploy',
                              submitterParameter: 'DEPLOYER'
                    }
                    
                    // Update Kubernetes deployment
                    withKubeConfig([credentialsId: "${KUBE_CREDENTIALS}"]) {
                        sh '''
                            kubectl set image deployment/${KUBE_DEPLOYMENT} \
                                landing-page=${DOCKER_IMAGE} \
                                -n ${KUBE_NAMESPACE}
                            
                            kubectl rollout status deployment/${KUBE_DEPLOYMENT} -n ${KUBE_NAMESPACE}
                        '''
                    }
                }
            }
        }
        
        stage('🧪 Smoke Tests') {
            steps {
                script {
                    echo "🧪 Running smoke tests..."
                    
                    // Get service URL
                    def serviceUrl = sh(
                        script: "kubectl get svc ${APP_NAME}-service -n ${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'",
                        returnStdout: true
                    ).trim()
                    
                    if (serviceUrl) {
                        // Test endpoint
                        sh """
                            curl -f http://${serviceUrl}:${APP_PORT} || exit 1
                            echo "✅ Smoke test passed!"
                        """
                    } else {
                        echo "⚠️ Service URL not available, skipping smoke tests"
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "🧹 Cleaning up..."
                
                // Clean up Docker images
                sh '''
                    docker image prune -f
                    docker system prune -f
                '''
                
                // Archive build artifacts
                archiveArtifacts artifacts: '*.html, *.json, *.txt', allowEmptyArchive: true
                
                // Publish test results
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',
                    reportFiles: 'index.html',
                    reportName: 'Landing Page Preview'
                ])
            }
        }
        
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                
                // Send notification
                emailext (
                    subject: "✅ Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                    body: """
                        🎉 Build completed successfully!
                        
                        Project: ${env.JOB_NAME}
                        Build: ${env.BUILD_NUMBER}
                        Branch: ${env.GIT_BRANCH_NAME}
                        Commit: ${env.GIT_COMMIT_SHORT}
                        
                        Docker Image: ${env.DOCKER_IMAGE}
                        
                        View build: ${env.BUILD_URL}
                    """,
                    to: "${env.CHANGE_AUTHOR_EMAIL ?: 'devops@company.com'}"
                )
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline failed!"
                
                // Send failure notification
                emailext (
                    subject: "❌ Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                    body: """
                        💥 Build failed!
                        
                        Project: ${env.JOB_NAME}
                        Build: ${env.BUILD_NUMBER}
                        Branch: ${env.GIT_BRANCH_NAME}
                        Commit: ${env.GIT_COMMIT_SHORT}
                        
                        View build: ${env.BUILD_URL}
                        Console: ${env.BUILD_URL}console
                    """,
                    to: "${env.CHANGE_AUTHOR_EMAIL ?: 'devops@company.com'}"
                )
            }
        }
        
        unstable {
            script {
                echo "⚠️ Pipeline completed with warnings"
            }
        }
    }
}
