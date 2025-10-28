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
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

// ... (Lines 1-61 remain the same until the start of Stage 3)

        stage('3. Build and Push Image') {
            steps {
                script {
                    // 1. Get Docker Login Credentials from Terraform Outputs
                    def acrLoginServer = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    def acrAdminUsername = sh(script: "terraform output -raw acr_admin_username", returnStdout: true).trim()
                    def acrAdminPassword = sh(script: "terraform output -raw acr_admin_password", returnStdout: true).trim()
                    def imageName = "${acrLoginServer}/demo-api:${env.BUILD_NUMBER}"

                    // 2. Perform Docker Operations based on OS
                    if (isUnix()) {
                        // Execution for Linux/macOS Agents
                        // NOTE: Removed the failing 'chmod' command. Docker access should be configured correctly 
                        // by mounting the socket with the correct user/group in the Jenkins Agent setup (Option A from previous response).
                        
                        sh "docker login ${acrLoginServer} -u ${acrAdminUsername} -p ${acrAdminPassword} --password-stdin <<< \"${acrAdminPassword}\""
                        sh "docker build -t ${imageName} ."
                        sh "docker push ${imageName}"
                    } else {
                        // Execution for Windows Agents (Use 'bat')
                        echo "Running Docker commands using BAT (Windows-compatible)..."
                        
                        // Windows uses bat for command execution
                        // NOTE: Docker commands work on Windows using 'bat' as Docker Desktop manages the communication pipe.
                        // We use the simpler method of piping the password into the login command for security and single-line execution.
                        bat "echo ${acrAdminPassword} | docker login ${acrLoginServer} -u ${acrAdminUsername} --password-stdin"
                        bat "docker build -t ${imageName} ."
                        bat "docker push ${imageName}"
                    }
                }
            }
        }

// ... (Continue to update Stage 4 to use platform-aware commands)

        stage('4. Deploy to Azure WebApp') {
            steps {
                script {
                    def rgName = sh(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                    def appName = sh(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                    def acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                    // Log in to Azure using the Service Principal (required for az webapp commands)
                    // The 'az login' command needs to be in a platform-specific block as well
                    if (isUnix()) {
                        sh "az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} --output none"
                        sh """
                        az webapp config container set \\
                            --name ${appName} \\
                            --resource-group ${rgName} \\
                            --docker-custom-image-name ${imageName} \\
                            --docker-registry-server-url https://${acrLogin}
                        """
                    } else {
                        // Windows uses bat
                        bat "az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} --output none"
                        // Note: Line continuation is done using '^' in Windows Batch, not '\'
                        bat """
                        az webapp config container set ^
                            --name ${appName} ^
                            --resource-group ${rgName} ^
                            --docker-custom-image-name ${imageName} ^
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
                    // Get the final website URL from Terraform
                    def siteUrl
                    if (isUnix()) {
                        siteUrl = sh(script: "terraform output -raw website_url", returnStdout: true).trim()
                    } else {
                        // Must use bat for output steps on Windows
                        siteUrl = bat(script: "terraform output -raw website_url", returnStdout: true).trim()
                    }
                    
                    echo "SUCCESS! Your application is live."
                    // Output the final URL in the build log
                    echo "Website URL: ${siteUrl}"
                }
            }
        }
    }
}