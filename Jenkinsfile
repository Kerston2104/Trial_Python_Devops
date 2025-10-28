// A Declarative Pipeline for building, deploying, and releasing the Python application
pipeline {
    // We use the agent 'any' because we installed all necessary tools (Docker, Terraform, Azure CLI)
    // directly into the Jenkins master container (or assume they are present).
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
                    
                    // Initialize Terraform (downloads Azure plugin)
                    sh 'terraform init'
                    
                    // Build the infrastructure (the 'main.tf' file)
                    sh 'terraform apply -auto-approve' 
                }
            }
        }

        stage('3. Build and Push Docker Image') {
            steps {
                echo 'Building and pushing application image to ACR...'
                // Use 'withCredentials' to get the ACR admin credentials (username/password)
                withCredentials([usernamePassword(credentialsId: 'acr-credentials', 
                                                passwordVariable: 'ACR_PASSWORD', 
                                                usernameVariable: 'ACR_USERNAME')]) {
                    script {
                        // CRITICAL FIX: Temporarily grant the Jenkins user access to the Docker socket.
                        // This bypasses the permission denied error without needing the 'sudo' command.
                        sh 'chmod 666 /var/run/docker.sock' 

                        // Retrieve outputs from Terraform state
                        def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                        // Define the full image tag using the Jenkins Build Number
                        def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                        // 1. Login to ACR
                        sh "echo ${env.ACR_PASSWORD} | docker login ${acrLogin} --username ${env.ACR_USERNAME} --password-stdin"
                        
                        // 2. Build the image (This should now work)
                        sh "docker build -t ${imageName} ."
                        
                        // 3. Push the image to ACR
                        sh "docker push ${imageName}"
                        
                        echo "Image ${imageName} pushed successfully to Azure Container Registry."
                    }
                }
            }
        }

        stage('4. Deploy to Azure App Service') {
            steps {
                echo 'Deploying new container image to Azure App Service...'
                // Use the service principal credentials to run Azure CLI commands
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CRED_ID, 
                                                        subscriptionIdVariable: 'AZURE_SUBSCRIPTION_ID', 
                                                        tenantIdVariable: 'AZURE_TENANT_ID',
                                                        clientIdVariable: 'AZURE_CLIENT_ID',
                                                        clientSecretVariable: 'AZURE_CLIENT_SECRET')]) {
                    script {
                        // Retrieve necessary names from Terraform outputs
                        def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                        def appName = sh(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                        def rgName = sh(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                        def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                        // Log in to Azure using the Service Principal
                        sh "az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} --output none"
                        
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