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

void getNuxeoImageVersion() {
  return sh(returnStdout: true, script: 'mvn org.apache.maven.plugins:maven-help-plugin:3.1.0:evaluate -Dexpression=nuxeo.platform.version -q -DforceStdout').trim();
}

String getVersion(referenceBranch, previewBranch) {
  String version = readMavenPom().getVersion()
  return (BRANCH_NAME == referenceBranch || BRANCH_NAME == previewBranch) ? version : version + "-${BRANCH_NAME}-${BUILD_NUMBER}"
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
  String image = "${NUXEO_DOCKER_REGISTRY}/${imageTag}"
  echo "Push ${image}"
  dockerPull(internalImage)
  dockerTag(internalImage, image)
  dockerPush(image)
}

pipeline {
  agent {
    label 'jenkins-nuxeo-package-11'
  }
  environment {
    APP_NAME = 'nuxeo-sample-supint-1819'
    MAVEN_OPTS = "$MAVEN_OPTS -Xms2g -Xmx2g  -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
    MAVEN_ARGS = '-B -nsu -Dnuxeo.skip.enforcer=true'
    REFERENCE_BRANCH = 'master'
    PREVIEW_BRANCH = 'task-SUPINT-1819-final'
    SCM_REF = "${getCommitSha1()}"
    VERSION = "${getVersion(REFERENCE_BRANCH, PREVIEW_BRANCH)}"
    NUXEO_DOCKER_REGISTRY = 'docker.packages.nuxeo.com'
    ORG = 'nuxeo'
    DOCKER_IMAGE_NAME1 = "nuxeo-sample-final1"
    PREVIEW_NAMESPACE1 = "${APP_NAME}-final1"
    DOCKER_IMAGE_NAME2 = "nuxeo-sample-final2"
    PREVIEW_NAMESPACE2 = "${APP_NAME}-final2"
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
          sh "mvn ${MAVEN_ARGS} -V -DskipDocker install"
        }
      }
      post {
        always {
          archiveArtifacts artifacts: '**/target/*.jar, **/target/nuxeo-*-package-*.zip'
        }
        success {
          setGitHubBuildStatus('compile', 'Compile', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('compile', 'Compile', 'FAILURE')
        }
      }
    }
    stage('Build Docker Images') {
      when {
        branch "${PREVIEW_BRANCH}"
      }
      steps {
        setGitHubBuildStatus('docker/build', 'Build Docker Images', 'PENDING')
        container('maven') {
          echo """
          ------------------------------------------
          Build Final Sample Docker Images
          ------------------------------------------
          Image tag: ${VERSION}
          Registry: ${DOCKER_REGISTRY}
          """
          withEnv(["NUXEO_IMAGE_VERSION=${getNuxeoImageVersion()}"]) {
            withCredentials([string(credentialsId: 'instance-clid', variable: 'INSTANCE_CLID')]) {
              script {
                // build and push Docker images to the Jenkins X internal Docker registry
                def dockerPath1 = 'docker/nuxeo-sample-final1-docker'
                sh "envsubst < ${dockerPath1}/skaffold.yaml > ${dockerPath1}/skaffold.yaml~gen"
                sh """#!/bin/bash +x
                  CLID=\$(echo -e "${INSTANCE_CLID}" | sed ':a;N;\$!ba;s/\\n/--/g') skaffold build -f ${dockerPath1}/skaffold.yaml~gen
                """
                def image1 = "${DOCKER_REGISTRY}/${ORG}/${DOCKER_IMAGE_NAME1}:${VERSION}"
                sh """
                  # waiting skaffold + kaniko + container-stucture-tests issue
                  #  see https://github.com/GoogleContainerTools/skaffold/issues/3907
                  docker pull ${image1}
                  container-structure-test test --image ${image1} --config ${dockerPath1}/test/*
                """
                def dockerPath2 = 'docker/nuxeo-sample-final2-docker'
                sh "envsubst < ${dockerPath2}/skaffold.yaml > ${dockerPath2}/skaffold.yaml~gen"
                sh """#!/bin/bash +x
                  CLID=\$(echo -e "${INSTANCE_CLID}" | sed ':a;N;\$!ba;s/\\n/--/g') skaffold build -f ${dockerPath2}/skaffold.yaml~gen
                """
                def image2 = "${DOCKER_REGISTRY}/${ORG}/${DOCKER_IMAGE_NAME2}:${VERSION}"
                sh """
                  # waiting skaffold + kaniko + container-stucture-tests issue
                  #  see https://github.com/GoogleContainerTools/skaffold/issues/3907
                  docker pull ${image2}
                  container-structure-test test --image ${image2} --config ${dockerPath2}/test/*
                """
              }
            }
          }
        }
      }
      post {
        success {
          setGitHubBuildStatus('docker/build', 'Build Docker Images', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/build', 'Build Docker Images', 'FAILURE')
        }
      }
    }
    stage('Test Docker Images') {
      steps {
        setGitHubBuildStatus('docker/test', 'Test Docker Images', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Test Docker image
          ----------------------------------------
          """
          script {
            image1 = "${DOCKER_REGISTRY}/${ORG}/${DOCKER_IMAGE_NAME1}:${VERSION}"
            echo "Test ${image1}"
            dockerPull(image1)
            echo 'Run image1'
            dockerRun(image1, 'nuxeoctl start')
            image2 = "${DOCKER_REGISTRY}/${ORG}/${DOCKER_IMAGE_NAME2}:${VERSION}"
            echo "Test ${image2}"
            dockerPull(image2)
            echo 'Run image2'
            dockerRun(image2, 'nuxeoctl start')
          }
        }
      }
      post {
        success {
          setGitHubBuildStatus('docker/test', 'Test Docker Images', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/test', 'Test Docker Images', 'FAILURE')
        }
      }
    }
    stage('Deploy Docker Images') {
      when {
        expression {
          branch "${PREVIEW_BRANCH}"
        }
      }
      steps {
        setGitHubBuildStatus('docker/deploy', 'Deploy Docker Images', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Deploy Docker Images
          ----------------------------------------
          Image tag: ${VERSION}
          Registry: ${DOCKER_REGISTRY}
          """
          dockerDeploy("${DOCKER_IMAGE_NAME1}")
          dockerDeploy("${DOCKER_IMAGE_NAME2}")
        }
      }
      post {
        success {
          setGitHubBuildStatus('docker/deploy', 'Deploy Docker Images', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/deploy', 'Deploy Docker Images', 'FAILURE')
        }
      }
    }
    stage('Deploy Previews') {
      when {
        branch "${PREVIEW_BRANCH}"
      }
      steps {
        setGitHubBuildStatus('preview', 'Deploy Previews', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Deploy preview environment
          ----------------------------------------"""
          dir('helm/preview') {

            script {
              // first substitute docker image names and versions
              sh """
                cp values.yaml values.yaml.orig
                cp values.yaml values.yaml.tosubst1
                DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME1} envsubst < values.yaml.tosubst1 > values.yaml
              """

              // second scale target namespace if exists and copy secrets to target namespace
              boolean nsExists1 = sh(returnStatus: true, script: "kubectl get namespace ${PREVIEW_NAMESPACE1}") == 0
              if (nsExists1) {
                // previous preview deployment needs to be scaled to 0 to be replaced correctly
                sh "kubectl --namespace ${PREVIEW_NAMESPACE1} scale deployment preview --replicas=0"
              } else {
                sh "kubectl create namespace ${PREVIEW_NAMESPACE1}"
              }
              sh "kubectl --namespace platform get secret kubernetes-docker-cfg -ojsonpath='{.data.\\.dockerconfigjson}' | base64 --decode > /tmp/config.json"
              sh """kubectl create secret generic kubernetes-docker-cfg \
                  --namespace=${PREVIEW_NAMESPACE1} \
                  --from-file=.dockerconfigjson=/tmp/config.json \
                  --type=kubernetes.io/dockerconfigjson --dry-run -o yaml | kubectl apply -f -"""

              // third build and deploy the chart
              // we use jx preview that gc the merged pull requests
              sh """
                jx step helm build --verbose
                mkdir target1 && helm template . --output-dir target1
                cp values.yaml target1/
                jx preview --namespace ${PREVIEW_NAMESPACE1} --verbose --source-url=https://github.com/nuxeo/nuxeo-customer-project-sample --preview-health-timeout 15m
              """

              // redo steps for second image
              sh """
                cp values.yaml.orig values.yaml.tosubst2
                DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME2} envsubst < values.yaml.tosubst2 > values.yaml
              """

              // second scale target namespace if exists and copy secrets to target namespace
              boolean nsExists2 = sh(returnStatus: true, script: "kubectl get namespace ${PREVIEW_NAMESPACE2}") == 0
              if (nsExists2) {
                // previous preview deployment needs to be scaled to 0 to be replaced correctly
                sh "kubectl --namespace ${PREVIEW_NAMESPACE2} scale deployment preview --replicas=0"
              } else {
                sh "kubectl create namespace ${PREVIEW_NAMESPACE2}"
              }
              sh "kubectl --namespace platform get secret kubernetes-docker-cfg -ojsonpath='{.data.\\.dockerconfigjson}' | base64 --decode > /tmp/config.json"
              sh """kubectl create secret generic kubernetes-docker-cfg \
                  --namespace=${PREVIEW_NAMESPACE2} \
                  --from-file=.dockerconfigjson=/tmp/config.json \
                  --type=kubernetes.io/dockerconfigjson --dry-run -o yaml | kubectl apply -f -"""

              // third build and deploy the chart
              // we use jx preview that gc the merged pull requests
              sh """
                jx step helm build --verbose
                mkdir target2 && helm template . --output-dir target2
                cp values.yaml target2/
                jx preview --namespace ${PREVIEW_NAMESPACE2} --verbose --source-url=https://github.com/nuxeo/nuxeo-customer-project-sample --preview-health-timeout 15m
              """
            }
          }
        }
      }
      post {
        always {
          archiveArtifacts allowEmptyArchive: true, artifacts: '**/requirements.lock, **/charts/*.tgz, **/target*/**/*.yaml'
        }
        success {
          setGitHubBuildStatus('preview', 'Deploy Previews', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('preview', 'Deploy Previews', 'FAILURE')
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
