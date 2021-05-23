pipeline {
    agent any
    environment {
        DOCKER_IMAGE_NAME = "ahmedsaleem/helloworldapp"
    }
        stages {
                stage('Build Docker Image') {
            when {
                branch 'master'
            }
            steps {
                script {
                    app = docker.build(DOCKER_IMAGE_NAME)
                    app.inside {
                        sh 'echo Hello, World!'
                    }
                }
            }
        }
        stage('Push Docker Image') {
            when {
                branch 'master'
            }
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
                        app.push("${env.BUILD_NUMBER}")
                        app.push("latest")
                    }
                }
            }
        }
		stage('Building Kuberenetes Cluster') {
			steps {
				build job: 'Pipeline_Build_Kuberenetes_Cluster'
				script {
					def logContent = Jenkins.getInstance().getItemByFullName(Pipeline_Build_Kuberenetes_Cluster).getBuildByNumber(Integer.parseInt(env.BUILD_NUMBER)).logFile.text
				}
			}
		}
    }
}
