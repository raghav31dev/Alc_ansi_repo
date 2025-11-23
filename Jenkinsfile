pipeline {
    agent any
    environment {
        ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/raghav31dev/Alc_ansi_repo.git'
            }
        }
    
        stage('Run Ansible Playbook') {
            steps {
                    sh '''
                        echo "Running Ansible..."
                        ansible-playbook -i web-ansible-project/inventory/hosts web-ansible-project/playbooks/web.yml
                    '''
            }
        }
        stage('Validate Deployment') {
            steps {
                script {
                    // Replace EC2_PUBLIC_IP
                    def output = sh(script: "curl -s http://13.201.115.126", returnStdout: true).trim()

                    if (!output.contains("Harika")) {
                        error("Webserver validation failed!")
                    }
                }
            }
        }
    }
    post {
        success {
            echo "Deployment Successful!"
        }
        failure {
            echo "Deployment Failed!"
        }
        always {
            echo "Pipeline Finished!"
        }
    }
}
