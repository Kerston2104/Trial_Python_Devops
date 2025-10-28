pipeline {
    // We use the agent 'any' because we installed all necessary tools (Docker, Terraform, Azure CLI)
    // directly into the Jenkins master container in the previous steps.
    agent any

    environment {
        // This MUST match the ID of the 'Azure Service Principal' credential you created in the Jenkins web UI.
        AZURE_CRED_ID = 'azure-credentials' 
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo 'Checking out source code from GitHub...'
                // Get all files from your GitHub repository
                git branch: 'main', url: 'https://github.com/Kerston2104/Trial_Python_Devops.git'
            }
        }
        
        stage('2. Build Infrastructure (Terraform)') {
            steps {
                echo 'Initializing and applying Azure Infrastructure via Terraform...'
                // The 'withCredentials' block injects the ARM_* environment variables
                // required by the Terraform Azure Provider to log in.
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CRED_ID, 
                                                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                                        tenantIdVariable: 'ARM_TENANT_ID',
                                                        clientIdVariable: 'ARM_CLIENT_ID',
                                                        clientSecretVariable: 'ARM_CLIENT_SECRET')]) {
                    
                    // Terraform will automatically find and use the ARM_... environment variables
                    
                    // Initialize Terraform (downloads Azure plugin)
                    sh 'terraform init'
                    
                    // Build the infrastructure (the 'main.tf' file)
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        
        stage('3. Build & Push App (Docker)') {
            steps {
                script {
                    echo 'Building and pushing Docker image to Azure Container Registry...'

                    // CRITICAL FIX 1: Fix the 'permission denied' error by changing socket access.
                    // This is required when Jenkins is containerized and needs to use the host's Docker daemon.
                    sh 'sudo chmod 666 /var/run/docker.sock' 

                    // Get outputs needed for Docker build and push
                    def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    // ACR credentials are sensitive and should be retrieved via output.tf
                    def acrAdminUsername = sh(script: "terraform output -raw acr_admin_username", returnStdout: true).trim()
                    def acrAdminPassword = sh(script: "terraform output -raw acr_admin_password", returnStdout: true).trim()
                    def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"
                    
                    // CRITICAL FIX 2: Log in to ACR before building/pushing.
                    // Use --password-stdin to safely pipe the password (which is sensitive and masked).
                    sh "echo ${acrAdminPassword} | docker login ${acrLogin} --username ${acrAdminUsername} --password-stdin"
                    
                    // 1. Build the image
                    sh "docker build -t ${imageName} ."
                    
                    // 2. Push the image
                    sh "docker push ${imageName}"

                    echo "Docker image built and pushed to ${imageName}."
                }
            }
        }

        stage('4. Deploy App (Azure)') {
            steps {
                echo 'Deploying image to Azure App Service...'
                // Re-wrap in withCredentials for the Azure CLI commands which need the Service Principal
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CRED_ID, 
                                                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                                        tenantIdVariable: 'ARM_TENANT_ID',
                                                        clientIdVariable: 'ARM_CLIENT_ID',
                                                        clientSecretVariable: 'ARM_CLIENT_SECRET')]) {
                    
                    script {
                        def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                        def appName = sh(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                        def rgName = sh(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                        def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                        // Log in to Azure using the Service Principal (required for az webapp commands)
                        sh "az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} --output none"
                        
                        // Set the Azure Web App to pull the new container image
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
        }

        stage('5. Get URL') {
            steps {
                script {
                    // Get the final website URL from Terraform
                    def siteUrl = sh(script: "terraform output -raw website_url", returnStdout: true).trim()
                    echo "SUCCESS! Your application is live."
                    // Output the final URL in the build log
                    echo "Website URL: ${siteUrl}"
                }
            }
        }
    }
}
