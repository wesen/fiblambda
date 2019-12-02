#!groovy

def app = "fiblambda"

def bucket = 'fib-lambda-s3-bucket'
def functionName = 'Fibonacci'
def region = 'us-east-1'

def ptNameVersion = "${app}-${UUID.randomUUID().toString().toLowerCase()}"

/*
Requirements:
- A credential set in Jenkins named 'api' with read access to all necessary repositories.
  - This SSH key must not have a passphrase, but that may be fixable in the future.
- A credential set in Jenkins named 'formlabs-docker' with read access to our Docker registry.
*/

podTemplate(name: ptNameVersion, label: ptNameVersion, containers: [
        containerTemplate(name: 'builder',
                image: 'docker.dev.formlabs.cloud/moria/lambda-builder:0.1.2',
                ttyEnabled: true,
                command: 'cat',
                args: ''),
        containerTemplate(name: 'docker',
                image: 'docker:17.09',
                ttyEnabled: true,
                command: 'cat',
                args: ''),
],
        imagePullSecrets: ["regcred"],
        volumes: [hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')]
) {

    node(ptNameVersion) {
        // Set up build arguments.
        def scmInfo = checkout([$class                           : 'GitSCM',
                                branches                         : scm.branches,
                                doGenerateSubmoduleConfigurations: false,
                                extensions                       : [
                                        [$class   : 'CloneOption',
                                         noTags   : true,
                                         depth    : 10,
                                         reference: '',
                                         shallow  : true]
                                ],
                                submoduleCfg                     : [],
                                userRemoteConfigs                : [[credentialsId: '0e3f9ed5-2e46-4480-80f6-1ebf92f8b71a',
                                                                     url          : 'git@github.com:wesen/fiblambda.git']]])
        def gitBranch = scmInfo.GIT_BRANCH
        def gitCommit = scmInfo.GIT_COMMIT
        def (remote, _, releaseType, version) = gitBranch.split("/")
        def zipName = "${releaseType}-${version}-${gitCommit}.zip"

        container("builder") {
            stage('Test'){
                sh 'go get -u golang.org/x/lint/golint'
                sh 'golint -set_exit_status'
                sh 'go vet .'
                sh 'go test .'
            }

            stage('Build'){
                sh 'GOOS=linux go build -o main main.go'
                sh "zip ${zipName} main"
            }

            withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'fiblambda',
                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]]) {
                sh 'AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} AWS_DEFAULT_REGION=us-east-1 aws sts get-caller-identity'
                sh 'sleep 1m' // SOOOO HACKY!!!

                stage('Push'){
                    sh "aws s3 cp ${zipName} s3://${bucket}"
                }

                stage('Deploy'){
                    sh "aws lambda update-function-code --function-name ${functionName} \
                            --s3-bucket ${bucket} \
                            --s3-key ${zipName} \
                            --region ${region}"
                }
            }
        }
    }
}
