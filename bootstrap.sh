#!/bin/bash -ex
SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))
TARGET_DIR=$SCRIPT_DIR/target
SCRIPT_BIN=$TARGET_DIR/node_modules/.bin/nuxeo-bootstrap

mkdir -p $TARGET_DIR && cd $_ && npm install nuxeo/nuxeo-cli#master
cd $SCRIPT_DIR

# Generator whole project
$SCRIPT_BIN multi-module --parent_package="com.customer.sample"
$SCRIPT_BIN operation --package="com.customer.sample.operation" --operation_name="CustomerOperation" --operation_label="Customer Operation Sample"
$SCRIPT_BIN listener --package="com.customer.sample.listener" --listener_name="CustomerListener" --events="aboutToCreate"
$SCRIPT_BIN listener --package="com.customer.sample.listener" --listener_name="CustomerAsyncListener" --events="documentCreated" --async="true"
$SCRIPT_BIN enricher --package="com.customer.sample.enricher" --enricher_name="CustomerEnricher" --entity_type="org.nuxeo.ecm.core.api.DocumentModel"
$SCRIPT_BIN service --package="com.customer.sample.service" --service_name="SampleService"
$SCRIPT_BIN polymer --name="sample" --route="sample"
$SCRIPT_BIN package --name="custom-package" --company="Customer Company"

mvn package
