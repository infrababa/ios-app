pipeline {
    agent any
    environment {
        PATH = "/opt/homebrew/bin:/opt/homebrew/opt/ruby/bin:/usr/local/bin:$PATH"
        LANG = 'en_US.UTF-8'
        LANGUAGE = 'en_US.UTF-8'
        LC_ALL = 'en_US.UTF-8'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', 
                          branches: [[name: '*/main']], 
                          userRemoteConfigs: [[url: 'https://github.com/infrababa/ios-app.git']]])
            }
        }
        stage('Install Dependencies') {
            steps {
                sh '''
                    echo "Starting dependency installation..."
                    # Check if Xcode command-line tools are installed
                    if ! xcode-select -p &> /dev/null; then
                        echo "Xcode command-line tools are not installed. Please run 'xcode-select --install' manually."
                        exit 1
                    fi

                    # Check and install Homebrew
                    if ! command -v brew >/dev/null 2>&1; then
                        echo "Installing Homebrew..."
                        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                        eval "$(/opt/homebrew/bin/brew shellenv)"
                    else
                        echo "Homebrew already installed: $(brew -v)"
                    fi

                    # Check and install Ruby
                    if ! command -v ruby >/dev/null 2>&1 || ! ruby -v | grep -q "ruby 3"; then
                        echo "Installing Ruby via Homebrew..."
                        brew install ruby
                    else
                        echo "Ruby already installed: $(ruby -v)"
                    fi

                    # Check and install Bundler
                    if ! command -v bundler >/dev/null 2>&1; then
                        echo "Installing Bundler..."
                        gem install bundler
                    else
                        echo "Bundler already installed: $(bundler -v)"
                    fi

                    # Check and install Fastlane
                    if ! command -v fastlane >/dev/null 2>&1; then
                        echo "Installing Fastlane..."
                        gem install fastlane
                    else
                        echo "Fastlane already installed: $(fastlane -v | grep "fastlane version")"
                    fi
                '''
            }
        }
        stage('Deploy to TestFlight') {
            steps {
                withCredentials([string(credentialsId: 'fastlane-api-key-id', variable: 'FASTLANE_APPLE_API_KEY_ID'),
                                 string(credentialsId: 'fastlane-api-key-issuer-id', variable: 'FASTLANE_APPLE_API_KEY_ISSUER_ID'),
                                 string(credentialsId: 'fastlane-api-key-key', variable: 'FASTLANE_APPLE_API_KEY_KEY'),
                                 string(credentialsId: 'match-password', variable: 'MATCH_PASSWORD')]) {
                    sh 'cd fastlane && fastlane deploy'
                }
            }
        }
    }
}