[![Jenkins](https://img.shields.io/jenkins/s/https/qa.nuxeo.org/jenkins/job/master/job/plugins_nuxeo-customer-project-sample-master/.svg?style=flat-square)](https://qa.nuxeo.org/jenkins/job/master/job/plugins_nuxeo-customer-project-sample-master/)

## Building

```bash
mvn clean install
```

### Requirements

See [CORG/Compiling Nuxeo from sources](http://doc.nuxeo.com/x/xION)

### Deploying

```bash
$NUXEO_HOME/bin/nuxeoctl mp-install nuxeo-customer-project-sample/nuxeo-customer-project-sample-package/target/nuxeo-customer-project-sample-package-*.zip
```

## Resources

### Nuxeo CLI

[www.npmjs.com/package/nuxeo-cli](https://www.npmjs.com/package/nuxeo-cli)

### Reporting issues

[jira.nuxeo.com/browse/NXP/component/14503/](https://jira.nuxeo.com/browse/NXP/component/14503/)

## Licensing

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)

## About Nuxeo

Nuxeo dramatically improves how content-based applications are built, managed and deployed, making customers more agile, innovative and successful. Nuxeo provides a next generation, enterprise ready platform for building traditional and cutting-edge content oriented applications. Combining a powerful application development environment with SaaS-based tools and a modular architecture, the Nuxeo Platform and Products provide clear business value to some of the most recognizable brands including Verizon, Electronic Arts, Sharp, FICO, the U.S. Navy, and Boeing. Nuxeo is headquartered in New York and Paris. More information is available at www.nuxeo.com.
