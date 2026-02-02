pipeline {
    agent any

    options {
        timestamps()
    }

    parameters {
        choice(
            name: 'DEPLOY_MODE',
            choices: ['delta', 'source', 'mdapi'],
            description: 'Deployment strategy'
        )
        choice(
            name: 'TEST_LEVEL',
            choices: ['NoTestRun', 'RunLocalTests'],
            description: 'Salesforce test level'
        )
    }

    environment {
        SF="/c/Program Files/sf/bin/sf"
        SF_ALIAS="CICD_DevHub"
        INSTANCE_URL="https://login.salesforce.com"
        SF_USERNAME="manisha.mondal@accenture.com"
        DELTA_DIR="delta"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/manishamondal/salesforce.git'
                    ]]
                ])
            }
        }

        stage('Verify Git') {
            steps {
                sh 'git branch -a'
                sh 'git log -1'
            }
        }

        stage('Salesforce Auth (JWT)') {
            steps {
                withCredentials([file(credentialsId: 'sfdx_jwt_key', variable: 'JWT_KEY_FILE'),string(credentialsId: 'sfdx_client_id', variable: 'CLIENT_ID')]) {
                    sh """
                    "$SF" org login jwt \
                      --client-id "$CLIENT_ID" \
                      --jwt-key-file "$JWT_KEY_FILE" \
                      --username "$SF_USERNAME" \
                      --instance-url "$INSTANCE_URL" \
                      --alias "$SF_ALIAS" \
                      --set-default
                    """
                }
            }
        }

        stage('Install Plugins') {
            steps {
                sh """
                "$SF" plugins install @salesforce/sfdx-scanner
                echo y | "$SF" plugins install sfdx-git-delta
                """
            }
        }

        stage('Generate Delta') {
            when {
                expression { params.DEPLOY_MODE == 'delta' }
            }
            steps {
                sh """
                rm -rf "$DELTA_DIR"
                mkdir -p "$DELTA_DIR"
                "$SF" sgd:source:delta \
                  --from origin/main \
                  --to HEAD \
                  --output "$DELTA_DIR" \
                  --generate-delta
                """
            }
        }

        stage('Static Code Analysis') {
            when {
                expression { params.DEPLOY_MODE == 'delta' }
            }
            steps {
                sh """
                mkdir -p /tmp/SCA
                "$SF" code-analyzer run \
                  --workspace "$DELTA_DIR" \
                  --rule-selector Recommended \
                  --output-file /tmp/SCA/sca-report.html
                """
            }
        }

        stage('Deploy - Delta (Source)') {
            when {
                expression { params.DEPLOY_MODE == 'delta' }
            }
            steps {
                sh """
                "$SF" deploy metadata \
                  --source-dir "$DELTA_DIR" \
                  --target-org "$SF_ALIAS" \
                  --test-level "$TEST_LEVEL" \
                  --wait 60
                """
            }
        }

        stage('Deploy - Full Source') {
            when {
                expression { params.DEPLOY_MODE == 'source' }
            }
            steps {
                sh """
                "$SF" deploy metadata \
                  --source-dir force-app \
                  --target-org "$SF_ALIAS" \
                  --test-level "$TEST_LEVEL" \
                  --wait 60
                """
            }
        }

        stage('Deploy - MDAPI') {
            when {
                expression { params.DEPLOY_MODE == 'mdapi' }
            }
            steps {
                sh """
                "$SF" deploy metadata \
                  --manifest manifest/package.xml \
                  --target-org "$SF_ALIAS" \
                  --test-level "$TEST_LEVEL" \
                  --wait 60
                """
            }
        }
    }

    post {
        success {
            echo '✅ Salesforce pipeline completed successfully'
        }
        failure {
            echo '❌ Salesforce pipeline failed'
        }
    }
}

