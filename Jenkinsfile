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
                    // --- Get Terraform Outputs (OS-AWARE) ---
                    // (Ensure you have implemented the OS-aware output fetching from the previous suggestion)
                    def acrLoginServer, acrAdminUsername, acrAdminPassword

                    if (isUnix()) {
                        acrLoginServer = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                        acrAdminUsername = sh(script: "terraform output -raw acr_admin_username", returnStdout: true).trim()
                        acrAdminPassword = sh(script: "terraform output -raw acr_admin_password", returnStdout: true).trim()
                    } else {
                        acrLoginServer = bat(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                        acrAdminUsername = bat(script: "terraform output -raw acr_admin_username", returnStdout: true).trim()
                        acrAdminPassword = bat(script: "terraform output -raw acr_admin_password", returnStdout: true).trim()
                    }
                    def imageName = "${acrLoginServer}/demo-api:${env.BUILD_NUMBER}"
                    
                    // --- Perform Docker Operations (OS-AWARE) ---
                    if (isUnix()) {
                        echo "Running Docker commands using official Docker CLI container (Fixing Permission Error)..."
                        
                        // FIX: Use 'docker run' to execute build/push commands.
                        // -v /var/run/docker.sock:/var/run/docker.sock maps the socket for access.
                        // -v ${PWD}:/workspace maps the Jenkins workspace to the container.
                        // -w /workspace sets the current working directory inside the container.
                        sh """
                          docker run --rm \\
                            -v /var/run/docker.sock:/var/run/docker.sock \\
                            -v ${PWD}:/workspace \\
                            -w /workspace \\
                            docker:cli \\
                            sh -c " \\
                              echo ${acrAdminPassword} | docker login ${acrLoginServer} -u ${acrAdminUsername} --password-stdin && \\
                              docker build -t ${imageName} . && \\
                              docker push ${imageName} \\
                            "
                        """
                    } else {
                        echo "Running Docker commands using BAT (Windows-compatible)..."
                        
                        // This block should still work if 'isUnix()' ever returns false
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
                    def rgName, appName, acrLogin
                    
                    if (isUnix()) {
                        rgName = sh(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                        appName = sh(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                        acrLogin = sh(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    } else {
                        rgName = bat(script: "terraform output -raw resource_group_name", returnStdout: true).trim()
                        appName = bat(script: "terraform output -raw app_service_name", returnStdout: true).trim()
                        acrLogin = bat(script: "terraform output -raw acr_login_server", returnStdout: true).trim()
                    }
                    
                    def imageName = "${acrLogin}/demo-api:${env.BUILD_NUMBER}"

                    // Log in to Azure using the Service Principal
                    if (isUnix()) {
                        sh "az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} --output none"
                        // Multi-line sh command
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
                        // Multi-line bat command uses '^' for continuation
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