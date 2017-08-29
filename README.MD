[![Jenkins](https://img.shields.io/jenkins/s/https/qa.nuxeo.org/jenkins/job/master/job/plugins_nuxeo-customer-project-sample-master/.svg?style=flat-square)](https://qa.nuxeo.org/jenkins/job/master/job/plugins_nuxeo-customer-project-sample-master/)

This plugin aim to show how to build and structure a common customer project. It is continuously built from [Nuxeo CLI](https://doc.nuxeo.com/nxdoc/nuxeo-cli/) using the `bootstrap.sh` script.

## Structure

It decribes a simple project, with several modules:

```
.
├── nuxeo-customer-project-sample-core: Core Module
│   └── src
│       ├── main
│       └── test
├── nuxeo-customer-project-sample-package: Nuxeo Package
│   └── src
│       └── main
└── nuxeo-customer-project-sample-web: Webapp Module (Polymer based)
    ├── images
    │   └── manifest
    ├── nuxeo
    │   ├── META-INF
    │   └── OSGI-INF
    ├── src
    └── test
```

### Core Module

A Core Module usually contains new Java based new features not supported by [Nuxeo Studio](https://doc.nuxeo.com/studio/nuxeo-studio/#page-title). You will find custom [Automation Operation](https://doc.nuxeo.com/nxdoc/content-automation-concepts/#operation), [Listeners](https://doc.nuxeo.com/nxdoc/events-and-listeners/#page-title), ...

Look at the [Nuxeo CLI](https://doc.nuxeo.com/nxdoc/nuxeo-cli/#page-title) documentation to discover what you can easily generate.
Full documentation about [Nuxeo Bundle](https://doc.nuxeo.com/nxdoc/runtime-and-component-model/).

### WebApp Module

A WebApp Module usually contains your Polymer Web Application as a standalone project to let you develop it as any other webapp.

Discover [Polymer Guide](https://doc.nuxeo.com/nxdoc/polymer-guide/#page-title) to help you starting a new project.

### Nuxeo Package

A Nuxeo Package usually contains installation instructions and optional constraints towards other packages (dependency, conflict). It is the easiest way to distribute a customer plugin, as it contains in one single ZIP file all the bundles, libraries, configuration properties and templates that are required to make the plugin work.

Full documentation about [Nuxeo Package](https://doc.nuxeo.com/nxdoc/creating-nuxeo-packages/).

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
