pipeline {
    agent none
    stages {
        stage('Docker') {
            agent {
                docker {
                    label 'docker-linux-x86_64-sif'
                    image 'docker:24-cli'
                    args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            when {
                anyOf {
                    branch 'uri';
                    buildingTag();
                }
            }
            environment {
                DOCKER_REGISTRY = 'ghcr.io'
                GITHUB_ORG = 'uri-life'
                DOCKER_IMAGE = "${env.DOCKER_REGISTRY}/${env.GITHUB_ORG}/mastodon"
                DOCKER_IMAGE_STREAMING = "${env.DOCKER_REGISTRY}/${env.GITHUB_ORG}/mastodon-streaming"
                GHCR_TOKEN = credentials('siliconforest-jenkins-github-pat-package-rw')
            }
            stages {
                stage('Prepare') {
                    steps {
                        script {
                                env.DOCKER_TAG = 'testing'
                                env.MASTODON_VERSION_PRERELEASE = 'testing'
                            if (env.BRANCH_NAME ==~ /^(v(?>[0-9]\.?){1,3})\/uri[0-9]+\.[0-9]+$/) {
                                env.DOCKER_LATEST = 'false'
                                env.MASTODON_VERSION_BUILDARG = "MASTODON_VERSION_PRERELEASE=${MASTODON_VERSION_PRERELEASE}"
                            } else {
                                env.DOCKER_TAG = env.TAG_NAME.replaceAll('\\+', '-')
                                env.MASTODON_VERSION_METADATA = env.TAG_NAME.replaceAll('(v(?>[0-9]\\.?){1,3})\\+', '')
                                env.DOCKER_LATEST = 'true'
                                env.MASTODON_VERSION_BUILDARG = "MASTODON_VERSION_METADATA=${MASTODON_VERSION_METADATA}"
                            }
                            env.GITHUB_REPOSITORY = "${params.URL}"
                            env.SOURCE_BASE_URL = "https://github.com/uri-life/mastodon" // I'm lazy. Will fix it later
                            env.SOURCE_TAG = "${env.BRANCH_NAME}"
                        }
                    }
                }
                stage('Docker login') {
                    steps {
                        sh 'echo $GHCR_TOKEN_PSW | docker login ghcr.io -u $GHCR_TOKEN_USR --password-stdin'
                    }
                }
                stage('Build') {
                    matrix {
                        axes {
                            axis {
                                name 'TARGET'
                                values 'amd64'
                            }
                        }
                        stages {
                            stage('Build platform specific image') {
                                steps {
                                    sh "docker build -t $DOCKER_IMAGE:$DOCKER_TAG-${TARGET} --platform linux/${TARGET} --build-arg \"GITHUB_REPOSITORY=${GITHUB_REPOSITORY}\" --build-arg \"SOURCE_BASE_URL=${SOURCE_BASE_URL}\" --build-arg \"SOURCE_TAG=${SOURCE_TAG}\" --build-arg \"${MASTODON_VERSION_BUILDARG}\" ."
                                    sh "docker build -t $DOCKER_IMAGE_STREAMING:$DOCKER_TAG-${TARGET} --platform linux/${TARGET} --build-arg \"GITHUB_REPOSITORY=${GITHUB_REPOSITORY}\" --build-arg \"SOURCE_BASE_URL=${SOURCE_BASE_URL}\" --build-arg \"SOURCE_TAG=${SOURCE_TAG}\" --build-arg \"${MASTODON_VERSION_BUILDARG}\" -f streaming/Dockerfile ."
                                    script {
                                        if (env.DOCKER_LATEST == 'true') {
                                            sh "docker tag $DOCKER_IMAGE:$DOCKER_TAG-${TARGET} $DOCKER_IMAGE:latest-${TARGET}"
                                            sh "docker tag $DOCKER_IMAGE_STREAMING:$DOCKER_TAG-${TARGET} $DOCKER_IMAGE_STREAMING:latest-${TARGET}"
                                        }
                                    }
                                }
                            }
                            stage('Push platform specific image') {
                                steps {
                                    sh "docker push $DOCKER_IMAGE:$DOCKER_TAG-${TARGET}"
                                    sh "docker push $DOCKER_IMAGE_STREAMING:$DOCKER_TAG-${TARGET}"
                                    script {
                                        if (env.DOCKER_LATEST == 'true') {
                                            sh "docker push $DOCKER_IMAGE:latest-${TARGET}"
                                            sh "docker push $DOCKER_IMAGE_STREAMING:latest-${TARGET}"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Docker manifest') {
                    steps {
                        sh "docker manifest create $DOCKER_IMAGE:$DOCKER_TAG --amend $DOCKER_IMAGE:$DOCKER_TAG-amd64"
                        sh "docker manifest create $DOCKER_IMAGE_STREAMING:$DOCKER_TAG --amend $DOCKER_IMAGE_STREAMING:$DOCKER_TAG-amd64"
                        script {
                            if (env.DOCKER_LATEST == 'true') {
                                sh "docker manifest create $DOCKER_IMAGE:latest --amend $DOCKER_IMAGE:latest-amd64"
                                sh "docker manifest create $DOCKER_IMAGE_STREAMING:latest --amend $DOCKER_IMAGE_STREAMING:latest-amd64"
                            }
                        }
                    }
                }
                stage('Docker push') {
                    steps {
                        sh "docker manifest push $DOCKER_IMAGE:$DOCKER_TAG"
                        sh "docker manifest push $DOCKER_IMAGE_STREAMING:$DOCKER_TAG"
                        script {
                            if (env.DOCKER_LATEST == 'true') {
                                sh "docker manifest push $DOCKER_IMAGE:latest"
                                sh "docker manifest push $DOCKER_IMAGE_STREAMING:latest"
                            }
                        }
                    }
                }
            }
            post {
                always {
                    sh 'docker logout "$DOCKER_REGISTRY"'
                }
            }
        }
    }
}
