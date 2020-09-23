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
  String image = "${NUXEO_DOCKER_REGISTRY}/${imageTag}"
  echo "Push ${image}"
  dockerPull(image)
  dockerTag(internalImage, image)
  dockerPush(image)
}

pipeline {
  agent {
    label 'jenkins-nuxeo-package-11'
  }
  triggers {
    upstream(
      threshold: hudson.model.Result.SUCCESS,
      upstreamProjects: "/nuxeo/nuxeo/master",
    )
  }
  environment {
    MAVEN_OPTS = "$MAVEN_OPTS -Xms2g -Xmx2g  -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
    MAVEN_ARGS = '-B -nsu -Dnuxeo.skip.enforcer=true'
    REFERENCE_BRANCH = 'master'
    SCM_REF = "${getCommitSha1()}"
    VERSION = "${getVersion(REFERENCE_BRANCH)}"
    NUXEO_DOCKER_REGISTRY = 'docker-private.packages.nuxeo.com'
    DOCKER_IMAGE_NAME = 'nuxeo-customer-project-sample'
    PREVIEW_NAMESPACE = "${DOCKER_IMAGE_NAME}-${BRANCH_NAME.toLowerCase()}"
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
          archiveArtifacts artifacts: '**/target/*.jar, **/target/nuxeo-*-package-*.zip', excludes: 'docker/nuxeo-customer-project-sample-docker/target/*'
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
        setGitHubBuildStatus('utests', 'Run Unit Tests', 'PENDING')
        container('maven') {
          echo """
          ----------------------------------------
          Run Unit Tests
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
          setGitHubBuildStatus('utests', 'Run Unit Tests', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('utests', 'Run Unit Tests', 'FAILURE')
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
        setGitHubBuildStatus('docker/build', 'Build Docker Image', 'PENDING')
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
                def dockerPath = 'docker/nuxeo-customer-project-sample-docker'
                sh "envsubst < ${dockerPath}/skaffold.yaml > ${dockerPath}/skaffold.yaml~gen"
                sh """#!/bin/bash +x
                  CLID=\$(echo -e "${INSTANCE_CLID}" | sed ':a;N;\$!ba;s/\\n/--/g') skaffold build -f ${dockerPath}/skaffold.yaml~gen
                """
                def image = "${DOCKER_REGISTRY}/${ORG}/${DOCKER_IMAGE_NAME}:${VERSION}"
                sh """
                  # waiting skaffold + kaniko + container-stucture-tests issue
                  #  see https://github.com/GoogleContainerTools/skaffold/issues/3907
                  docker pull ${image}
                  container-structure-test test --image ${image} --config ${dockerPath}/test/*
                """
              }
            }
          }
        }
      }
      post {
        success {
          setGitHubBuildStatus('docker/build', 'Build Docker Image', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/build', 'Build Docker Image', 'FAILURE')
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
        setGitHubBuildStatus('docker/deploy', 'Deploy Docker Image', 'PENDING')
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
          setGitHubBuildStatus('docker/deploy', 'Deploy Docker Image', 'SUCCESS')
        }
        unsuccessful {
          setGitHubBuildStatus('docker/deploy', 'Deploy Docker Image', 'FAILURE')
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