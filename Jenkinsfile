pipeline {
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
                git branch: 'main', 
                url: 'https://github.com/Kerston2104/Trial_Python_Devops.git'
            }
        }
        
        stage('2. Build Infrastructure (Terraform)') {
            steps {
                echo 'Initializing and applying Azure Infrastructure via Terraform...'
                // Inject the ARM_* environment variables for the Terraform Azure Provider
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CRED_ID, 
                                                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                                        tenantIdVariable: 'ARM_TENANT_ID',
                                                        clientIdVariable: 'ARM_CLIENT_ID',
                                                        clientSecretVariable: 'ARM_CLIENT_SECRET')]) {
                    
                    // FIX: Run Terraform commands inside the official Terraform Docker image (resolves 'terraform: not found')
                    docker.image('hashicorp/terraform:1.7.0').inside {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('3. Build and Push Image') {
            steps {
                script {
                    def acrLoginServer, acrAdminUsername, acrAdminPassword

                    // Get Terraform Outputs: Must run inside the Terraform container to find the tool.
                    // This is now correctly scoped within the 'script' block.
                    docker.image('hashicorp/terraform:1.7.0').inside {
                        acrLoginServer = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                        acrAdminUsername = sh(script: "terraform output -raw acr_admin_username", returnStdout: true).trim()
                        acrAdminPassword = sh(script: "terraform output -raw acr_admin_password", returnStdout: true).trim()
                    }
                    def imageName = "${acrLoginServer}/demo-api:${env.BUILD_NUMBER}"
                    
                    // FIX: Clean Docker commands (relying on the successful Windows host fix)
                    echo "Running clean Docker commands..."
                    
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
                    def rgName, appName, acrLogin
                    
                    // Get Terraform Outputs: Must run inside the Terraform container.
                    docker.image('hashicorp/terraform:1.7.0').inside {
                        rgName = sh(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                        appName = sh(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                        acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    }
                    
                    def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                    // FIX: Run Azure CLI commands inside the official Azure CLI Docker image (resolves 'az: not found')
                    docker.image('mcr.microsoft.com/azure-cli:2.55.0').inside {
                        // Log in to Azure using the Service Principal
                        sh "az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} --output none"
                        
                        // Set the container image on the Azure WebApp
                        sh """
                        az webapp config container set \\
                            --name ${appName} \\
                            --resource-group ${rgName} \\
                            --docker-custom-image-name ${imageName} \\
                            --docker-registry-server-url https://${acrLogin}
                        """
                    }
                    echo "Deployment command sent successfully. Azure will now pull the new image."
                }
            }
        }

        stage('5. Get URL') {
            steps {
                script {
                    def siteUrl
                    
                    // Get the final website URL from Terraform
                    docker.image('hashicorp/terraform:1.7.0').inside {
                        siteUrl = sh(script: "terraform output -raw website_url", returnStdout: true).trim()
                    }
                    
                    echo "SUCCESS! Your application is live."
                    echo "Website URL: ${siteUrl}"
                }
            }
        }
    }
}