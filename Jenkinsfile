 /*
 * (C) Copyright 2020 Nuxeo (http://nuxeo.com/) and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors:
 *     Antoine Taillefer <ataillefer@nuxeo.com>
 *     Thomas Roger <troger@nuxeo.com>
 *     Kevin Leturc <kleturc@nuxeo.com>
 *     Anahide Tchertchian <atchertchian@nuxeo.com>
 */
properties([
  [$class: 'GithubProjectProperty', projectUrlStr: 'https://github.com/nuxeo/nuxeo-customer-project-sample/'],
  [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', daysToKeepStr: '60', numToKeepStr: '60', artifactNumToKeepStr: '5']],
  disableConcurrentBuilds(),
])

void setGitHubBuildStatus(String context, String message, String state) {
  step([
    $class: 'GitHubCommitStatusSetter',
    reposSource: [$class: 'ManuallyEnteredRepositorySource', url: 'https://github.com/nuxeo/nuxeo-customer-project-sample'],
    contextSource: [$class: 'ManuallyEnteredCommitContextSource', context: context],
    statusResultSource: [$class: 'ConditionalStatusResultSource', results: [[$class: 'AnyBuildResult', message: message, state: state]]],
  ])
}

String getCurrentNamespace() {
  container('maven') {
    return sh(returnStdout: true, script: "kubectl get pod ${NODE_NAME} -ojsonpath='{..namespace}'")
  }
}

void getNuxeoImageVersion() {
  return sh(returnStdout: true, script: 'mvn org.apache.maven.plugins:maven-help-plugin:3.1.0:evaluate -Dexpression=nuxeo.platform.version -q -DforceStdout').trim();
}

String getVersion(referenceBranch) {
  String version = readMavenPom().getVersion()
  return BRANCH_NAME == referenceBranch ? version : version + "-${BRANCH_NAME}-${BUILD_NUMBER}"
}

String getCommitSha1() {
  return sh(returnStdout: true, script: 'git rev-parse HEAD').trim();
}

void dockerPull(String image) {
  sh "docker pull ${image}"
}

void dockerRun(String image, String command) {
  sh "docker run --rm ${image} ${command}"
}

void dockerTag(String image, String tag) {
  sh "docker tag ${image} ${tag}"
}

void dockerPush(String image) {
  sh "docker push ${image}"
}

void dockerDeploy(String imageName) {
  String imageTag = "${ORG}/${imageName}:${VERSION}"
  String internalImage = "${DOCKER_REGISTRY}/${imageTag}"
  String image = "${PRIVATE_DOCKER_REGISTRY}/${imageTag}"
  echo "Push ${image}"
  dockerPull(internalImage)
  dockerTag(internalImage, image)
  dockerPush(image)
}

pipeline {
  agent {
    label 'jenkins-nuxeo-package-lts-2021'
  }
  triggers {
    upstream(
      threshold: hudson.model.Result.SUCCESS,
      upstreamProjects: "/nuxeo/lts/nuxeo/2021",
    )
  }
  environment {
    CURRENT_NAMESPACE = getCurrentNamespace()
    APP_NAME = 'nuxeo-customer-project-sample'
    MAVEN_OPTS = "$MAVEN_OPTS -Xms2g -Xmx2g  -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
    MAVEN_ARGS = '-B -nsu'
    REFERENCE_BRANCH = '2021'
    SCM_REF = "${getCommitSha1()}"
    VERSION = "${getVersion(REFERENCE_BRANCH)}"
    DOCKER_IMAGE_NAME = "${APP_NAME}"
    PREVIEW_NAMESPACE = "${APP_NAME}-${BRANCH_NAME.toLowerCase()}"
    ORG = 'nuxeo'
  }
  stages {
    stage('Set Labels') {
      steps {
        container('maven') {
          echo """
          ----------------------------------------
          Set Kubernetes resource labels
          ----------------------------------------
          """
          echo "Set label 'branch: ${BRANCH_NAME}' on pod ${NODE_NAME}"
          sh """
            kubectl label pods ${NODE_NAME} branch=${BRANCH_NAME}
          """
        }
      }
    }
    stage('Compile') {
      steps {
        setGitHubBuildStatus('compile', 'Compile', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Compile
          ----------------------------------------"""
          echo "MAVEN_OPTS=$MAVEN_OPTS"
          sh "mvn ${MAVEN_ARGS} -V -DskipTests -DskipDocker install"
        }
      }
      post {
        always {
          archiveArtifacts artifacts: '**/target/*.jar, **/target/nuxeo-*-package-*.zip', excludes: 'nuxeo-customer-project-sample-docker/target/*'
        }
        success {
          setGitHubBuildStatus('compile', 'Compile', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('compile', 'Compile', 'FAILURE')
        }
      }
    }
    stage('Run Unit Tests') {
      steps {
        setGitHubBuildStatus('utests', 'Run unit tests', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Run unit tests
          ----------------------------------------"""
          echo "MAVEN_OPTS=$MAVEN_OPTS"
          sh "mvn  ${MAVEN_ARGS} test"
        }
      }
      post {
        always {
          archiveArtifacts artifacts: '**/target/**/*.log'
          junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true
        }
        success {
          setGitHubBuildStatus('utests', 'Run unit tests', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('utests', 'Run unit tests', 'FAILURE')
        }
      }
    }
    stage('Build Docker Image') {
      when {
        anyOf {
          branch 'PR-*'
          branch "${REFERENCE_BRANCH}"
        }
      }
      steps {
        setGitHubBuildStatus('docker/build', 'Build Docker image', 'PENDING')
        container('maven') {
          echo """
          ------------------------------------------
          Build customer project sample Docker image
          ------------------------------------------
          Image tag: ${VERSION}
          Registry: ${DOCKER_REGISTRY}
          """
          withEnv(["NUXEO_IMAGE_VERSION=${getNuxeoImageVersion()}"]) {
            withCredentials([string(credentialsId: 'instance-clid', variable: 'INSTANCE_CLID')]) {
              script {
                // build and push Docker image to the Jenkins X internal Docker registry
                env.DOCKER_PATH = 'nuxeo-customer-project-sample-docker'
                sh "envsubst < ${DOCKER_PATH}/skaffold.yaml > ${DOCKER_PATH}/skaffold.yaml~gen"
                sh '''#!/bin/bash +x
                  CLID=\$(echo -e "${INSTANCE_CLID}" | sed ':a;N;\$!ba;s/\\n/--/g') skaffold build -f $DOCKER_PATH/skaffold.yaml~gen
                '''
                def image = "${DOCKER_REGISTRY}/${ORG}/${DOCKER_IMAGE_NAME}:${VERSION}"
                // using test in skaffold.yaml doesn't seem to work with a remote image,
                // despite https://github.com/GoogleContainerTools/skaffold/issues/3907 supposedly solved
                sh """
                  docker pull ${image}
                  container-structure-test test --image ${image} --config ${DOCKER_PATH}/test/*
                """
              }
            }
          }
        }
      }
      post {
        success {
          setGitHubBuildStatus('docker/build', 'Build Docker image', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/build', 'Build Docker image', 'FAILURE')
        }
      }
    }
    stage('Test Docker image') {
      steps {
        setGitHubBuildStatus('docker/test', 'Test Docker image', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Test Docker image
          ----------------------------------------
          """
          script {
            // nuxeo image
            image = "${DOCKER_REGISTRY}/${ORG}/${DOCKER_IMAGE_NAME}:${VERSION}"
            echo "Test ${image}"
            dockerPull(image)
            echo 'Run image'
            dockerRun(image, 'nuxeoctl start')
          }
        }
      }
      post {
        success {
          setGitHubBuildStatus('docker/test', 'Test Docker image', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/test', 'Test Docker image', 'FAILURE')
        }
      }
    }
    stage('Deploy Docker Image') {
      when {
        // we actually don't want to deploy the built image to an external Docker registry
        // if needed, uncomment the following line and remove the false expression
        // branch "${REFERENCE_BRANCH}"
        expression {
          return false
        }
      }
      steps {
        setGitHubBuildStatus('docker/deploy', 'Deploy Docker image', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Deploy Docker image
          ----------------------------------------
          Image tag: ${VERSION}
          Registry: ${DOCKER_REGISTRY}
          """
          dockerDeploy("${DOCKER_IMAGE_NAME}")
        }
      }
      post {
        success {
          setGitHubBuildStatus('docker/deploy', 'Deploy Docker image', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/deploy', 'Deploy Docker image', 'FAILURE')
        }
      }
    }
    stage('Deploy Preview') {
      when {
        branch 'PR-*'
      }
      steps {
        setGitHubBuildStatus('preview', 'Deploy preview', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Deploy preview environment
          ----------------------------------------"""
          dir('helm/preview') {

            script {
              // first substitute docker image names and versions
              sh """
                mv values.yaml values.yaml.tosubst
                envsubst < values.yaml.tosubst > values.yaml
              """

              // second scale target namespace if exists and copy secrets to target namespace
              boolean nsExists = sh(returnStatus: true, script: "kubectl get namespace ${PREVIEW_NAMESPACE}") == 0
              if (nsExists) {
                // previous preview deployment needs to be scaled to 0 to be replaced correctly
                sh "kubectl --namespace ${PREVIEW_NAMESPACE} scale deployment preview --replicas=0"
              } else {
                sh "kubectl create namespace ${PREVIEW_NAMESPACE}"
              }
              sh "kubectl --namespace platform get secret kubernetes-docker-cfg -ojsonpath='{.data.\\.dockerconfigjson}' | base64 --decode > /tmp/config.json"
              sh """kubectl create secret generic kubernetes-docker-cfg \
                  --namespace=${PREVIEW_NAMESPACE} \
                  --from-file=.dockerconfigjson=/tmp/config.json \
                  --type=kubernetes.io/dockerconfigjson --dry-run -o yaml | kubectl apply -f -"""

              // third build and deploy the chart
              // we use jx preview that gc the merged pull requests
              sh """
                helm init --client-only --stable-repo-url=https://charts.helm.sh/stable
                helm repo add local-jenkins-x http://jenkins-x-chartmuseum:8080
                jx step helm build --verbose
                mkdir target && helm template . --output-dir target
                cp values.yaml target/
                jx preview --namespace ${PREVIEW_NAMESPACE} --verbose --source-url=https://github.com/nuxeo/nuxeo-customer-project-sample --preview-health-timeout 15m
              """
            }
          }
        }
      }
      post {
        always {
          archiveArtifacts allowEmptyArchive: true, artifacts: '**/requirements.lock, **/charts/*.tgz, **/target/**/*.yaml'
        }
        success {
          setGitHubBuildStatus('preview', 'Deploy preview', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('preview', 'Deploy preview', 'FAILURE')
        }
      }
    }
  }
  post {
    always {
      script {
        if (BRANCH_NAME == REFERENCE_BRANCH) {
          // update JIRA issue
          step([$class: 'JiraIssueUpdater', issueSelector: [$class: 'DefaultIssueSelector'], scm: scm])
        }
      }
    }
  }
}
