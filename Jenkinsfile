pipeline {
    agent any

    environment {
        // ID of your Azure credentials in Jenkins
        AZURE_CRED_ID = 'azure-credentials' 
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                // Get all 6 files from GitHub
                git branch: 'main', url: 'https://github.com/Kerston2104/Trial_Python_Devops.git'
            }
        }
        
        // *** THIS STAGE HAS BEEN FIXED ***
        stage('2. Build Infrastructure (Terraform)') {
            steps {
                // We must wrap our Terraform commands with the Azure credentials
                // so Terraform can log in.
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
                    // Get the info for the Container Registry
                    def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    def acrUser = sh(script: "terraform output -raw acr_admin_username", returnStdout: true).trim()
                    def acrPass = sh(script: "terraform output -raw acr_admin_password", returnStdout: true).trim()
                    
                    // Build the Docker image (using the 'Dockerfile')
                    def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"
                    sh "docker build -t ${imageName} ."
                    
                    // Log in and push the image to Azure
                    sh "docker login ${acrLogin} -u ${acrUser} -p ${acrPass}"
                    sh "docker push ${imageName}"
                }
            }
        }
        
        stage('4. Deploy App (Azure)') {
            steps {
                // This stage was already correct
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CRED_ID, 
                                                        subscriptionId: '04af6da8-93f0-4e3f-8823-10577bf91c60', 
                                                        tenantId: 'd6739ca7-e1f1-4780-afcf-48c1ad1ce84b',
                                                        clientIdVariable: 'AZURE_CLIENT_ID',
                                                        clientSecretVariable: 'AZURE_CLIENT_SECRET',
                                                        tenantIdVariable: 'AZURE_TENANT_ID')]) {
                    
                    script {
                        def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                        def appName = sh(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                        def rgName = sh(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                        def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                        // Log in to Azure
                        sh "az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}"
                        
                        sh """
                        az webapp config container set \
                            --name ${appName} \
                            --resource-group ${rgName} \
                            --docker-custom-image-name ${imageName} \
                            --docker-registry-server-url https://${acrLogin}
                        """
                    }
                }
            }
        }

        stage('5. Get URL') {
            steps {
                script {
                    // Get the final website URL from Terraform
                    def siteUrl = sh(script: "terraform output -raw website_url", returnStdout: true).trim()
                    echo "SUCCESS! App is live at: ${siteUrl}"
                }
            }
        }
    }
}

