pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', 
                          branches: [[name: '*/main']], 
                          userRemoteConfigs: [[url: 'https://github.com/terateck/ios-app.git']]])
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    mkdir -p artifacts
                    swiftlint --config SimpleLogin/.swiftlint.yml --reporter junit > artifacts/swiftlint_results.xml
                '''
            }
            post {
                failure {
                    archiveArtifacts artifacts: 'artifacts/*', allowEmptyArchive: true
                }
            }
        }
        stage('Build and Clean') {
            steps {
                sh 'cd fastlane && fastlane build'
                sh 'cd fastlane && fastlane clean_up'
            }
        }
    }
}