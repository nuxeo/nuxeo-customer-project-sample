#!/bin/bash -ex
SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))
TARGET_DIR=${SCRIPT_DIR}/target
SCRIPT_BIN=${TARGET_DIR}/node_modules/.bin/nuxeo

git clean -fd
rm -rf .yo-rc.json pom.xml nuxeo-customer*

mkdir -p ${TARGET_DIR} && cd $_ && npm install nuxeo/nuxeo-cli#master
cd ${SCRIPT_DIR}

# Generator whole project
${SCRIPT_BIN} b multi-module --params.parent_package="com.customer.sample" --params.use_bom=true --params.use_nuxeo_bom=true --params.nuxeo_version="11.4" --batch
${SCRIPT_BIN} b operation --params.package="com.customer.sample.operation" --params.operation_name="CustomerOperation" --params.operation_label="Customer Operation Sample" --params.super_version="11.4" --batch
${SCRIPT_BIN} b listener --params.package="com.customer.sample.listener" --params.listener_name="CustomerListener" --params.events="aboutToCreate" --params.super_version="11.4" --batch
${SCRIPT_BIN} b listener --params.package="com.customer.sample.listener" --params.listener_name="CustomerAsyncListener" --params.events="documentCreated" --params.async="true" --params.super_version="11.4" --batch
${SCRIPT_BIN} b enricher --params.package="com.customer.sample.enricher" --params.enricher_name="CustomerEnricher" --params.entity_type="org.nuxeo.ecm.core.api.DocumentModel" --params.super_version="11.4" --batch
${SCRIPT_BIN} b service --params.package="com.customer.sample.service" --params.service_name="SampleService" --params.super_version="11.4" --batch
# NXP-29691: Disable web module for now
#$SCRIPT_BIN b polymer --params.name="sample" --params.route="sample" --params.super_version="11.4"
${SCRIPT_BIN} b package --params.name="custom-package" --params.company="Customer Company" --params.super_version="11.4" --batch

# Link Studio Project
${SCRIPT_BIN} studio link --params.username=${NOS_USERNAME} --params.password=${NOS_TOKEN} --params.project=jenkins_pub-SANDBOX --params.settings=false

# Add Docker module
${SCRIPT_BIN} --batch b docker
