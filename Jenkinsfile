pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'hello-world'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
    }

    stages {
        stage('Test') {
            steps {
                sh 'npm install'
                sh 'npm test'
                sh 'npm run test:coverage'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Run OpenTofu Tests') {
            steps {
                dir('terraform') {
                    sh 'tofu init'
                    sh 'tofu test'
                }
            }
        }

        stage('Deploy to Development') {
            when {
                branch 'develop'
            }
            steps {
                sh "helm upgrade --install hello-world ./helm/hello-world --namespace applications --set image.tag=${DOCKER_TAG}"
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Approve deployment to production?'
                }
                sh "helm upgrade --install hello-world ./helm/hello-world --namespace applications --set image.tag=${DOCKER_TAG} -f helm/hello-world/values-prod.yaml"
            }
        }
    }

    post {
        always {
            junit '**/test-results.xml'
            publishHTML(target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'coverage',
                reportFiles: 'index.html',
                reportName: 'Coverage Report'
            ])
        }
        failure {
            emailext (
                subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                body: "Pipeline failure. Please check: ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
}
