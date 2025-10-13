pipeline {
    agent any

    environment {
        DOCKERHUB_USER = '3booda24'
        APP_IMAGE = 'vprofileapp'
        DB_IMAGE = 'vprofiledb'
        TAG = 'latest'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/abdelrahmanonline4/dockerized-microservices.git'
            }
        }

        stage('Build App Image') {
            steps {
                script {
                    dir('Docker-files/app') {
                        sh "docker build -t ${DOCKERHUB_USER}/${APP_IMAGE}:${TAG} ."
                    }
                }
            }
        }

        stage('Build DB Image') {
            steps {
                script {
                    dir('Docker-files/db') {
                        sh "docker build -t ${DOCKERHUB_USER}/${DB_IMAGE}:${TAG} ."
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                    echo $PASS | docker login -u $USER --password-stdin
                    docker push ${DOCKERHUB_USER}/${APP_IMAGE}:${TAG}
                    docker push ${DOCKERHUB_USER}/${DB_IMAGE}:${TAG}
                    docker logout
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                kubectl apply -f .
                kubectl rollout status deployment/vprofileapp-deployment || true
                kubectl rollout status deployment/vprofiledb-deployment || true
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Build and deployment completed successfully."
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
