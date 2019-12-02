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
                image: 'docker.dev.formlabs.cloud/moria/jenkins:2.150.3',
                ttyEnabled: true,
                command: 'cat',
                args: ''),
        containerTemplate(name: 'docker',
                image: 'docker:17.09',
                ttyEnabled: true,
                command: 'cat',
                args: ''),
        containerTemplate(name: 'argo-cd-tools',
                image: 'docker.dev.formlabs.cloud/moria/argo-cd-tools:latest',
                alwaysPullImage: true,
                ttyEnabled: true,
                command: 'cat',
                args: '',
                envVars: [envVar(key: 'GIT_SSH_COMMAND', value: 'ssh -o StrictHostKeyChecking=no'),
                          envVar(key: 'ARGOCD_SERVER', value: argocdServer)]),
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
        def (remote, _, tool, releaseType, version) = gitBranch.split("/")
        def tag = "${env.BUILD_TAG}-${gitCommit}"
        def zipName = "${gitBranch}-${gitCommit}.zip"

        container("builder") {
            withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'fiblambda',
                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]]) {
                sh 'AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} AWS_DEFAULT_REGION=us-east-1 aws sts get-caller-identity'
                sh 'sleep 1m' // SOOOO HACKY!!!
            }

            withCredentials([sshUserPrivateKey(
                    credentialsId: 'moria_jenkins_write_deploy',
                    keyFileVariable: 'GIT_SSH_KEY')
            ]) {
                sh "mkdir -p /root/ && cp \$GIT_SSH_KEY /root/.ssh/id_rsa && chmod 400 /root/.ssh/id_rsa"
            }

            stage('Test'){
                sh 'go get -u github.com/golang/lint/golint'
                sh 'go get -t ./...'
                sh 'golint -set_exit_status'
                sh 'go vet .'
                sh 'go test .'
            }

            stage('Build'){
                sh 'GOOS=linux go build -o main main.go'
                sh "zip ${zipName} main"
            }

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
