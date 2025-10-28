pipeline {
    // Agent is clean, all tools are now in the custom image path
    agent any

    environment {
        // This MUST match the ID of the 'Azure Service Principal' credential you created in the Jenkins web UI.
        AZURE_CRED_ID = 'azure-credentials' 
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo 'Checking out source code from GitHub...'
                git branch: 'main', 
                url: 'https://github.com/Kerston2104/Trial_Python_Devops.git'
            }
        }
        
        stage('2. Build Infrastructure (Terraform)') {
            steps {
                echo 'Initializing and applying Azure Infrastructure via Terraform...'
                // Tools (terraform) are now available directly in the shell
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CRED_ID, 
                                                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                                        tenantIdVariable: 'ARM_TENANT_ID',
                                                        clientIdVariable: 'ARM_CLIENT_ID',
                                                        clientSecretVariable: 'ARM_CLIENT_SECRET')]) {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('3. Build and Push Image') {
            steps {
                script {
                    // Get Terraform Outputs using the installed Terraform tool
                    def acrLoginServer = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    def acrAdminUsername = sh(script: "terraform output -raw acr_admin_username", returnStdout: true).trim()
                    def acrAdminPassword = sh(script: "terraform output -raw acr_admin_password", returnStdout: true).trim()
                    def imageName = "${acrLoginServer}/demo-api:${env.BUILD_NUMBER}"
                    
                    // Docker commands work directly because of the Windows pipe fix
                    echo "Running Docker commands..."
                    
                    sh """
                      echo ${acrAdminPassword} | docker login ${acrLoginServer} -u ${acrAdminUsername} --password-stdin
                      docker build -t ${imageName} .
                      docker push ${imageName}
                    """
                }
            }
        }

        stage('4. Deploy to Azure WebApp') {
            steps {
                script {
                    // Get Terraform Outputs
                    def rgName = sh(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                    def appName = sh(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                    def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                    // Azure CLI commands work directly (installed in custom image)
                    sh "az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} --output none"
                    
                    sh """
                    az webapp config container set \\
                        --name ${appName} \\
                        --resource-group ${rgName} \\
                        --docker-custom-image-name ${imageName} \\
                        --docker-registry-server-url https://${acrLogin}
                    """
                    echo "Deployment command sent successfully. Azure will now pull the new image."
                }
            }
        }

        stage('5. Get URL') {
            steps {
                script {
                    // Get the final website URL from Terraform
                    def siteUrl = sh(script: "terraform output -raw website_url", returnStdout: true).trim()
                    
                    echo "SUCCESS! Your application is live."
                    echo "Website URL: ${siteUrl}"
                }
            }
        }
    }
}