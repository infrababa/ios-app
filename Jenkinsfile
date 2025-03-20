pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', 
                          branches: [[name: '*/main']], 
                          userRemoteConfigs: [[url: 'https://github.com/terateck/simple-ios-app.git', credentialsId: 'git_token']]])
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'brew install swiftlint'
                sh 'gem install bundler fastlane'
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