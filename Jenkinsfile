env.AWS_DEFAULT_REGION = 'ap-southeast-1'

node {
  withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'shifa4u_credentials',
                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]])
}
	
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
				
		stage('Terraform Init') {
            sh label: 'terraform init', script: "/tmp/terraform init -backend-config \"bucket=shifa4u-testbucket\""
        }
		
        stage('Terrafrom Plan') {
        sh label: 'terraform plan', script: "/tmp/terraform plan -out=tfplan -input=false"
            script {
                timeout(time: 10, unit: 'MINUTES') {
                    input(id: "Deploy Gate", message: "Deploy Kubernets environment?", ok: 'Deploy')
                }
            }
		}
				
		stage('Terraform Apply') {
            sh label: 'terraform apply', script: "terraform apply -lock=false -input=false tfplan"
        }
				
	}	
				
}
