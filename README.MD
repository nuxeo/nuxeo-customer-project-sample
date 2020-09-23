[![Jenkins](https://img.shields.io/jenkins/s/https/qa.nuxeo.org/jenkins/job/master/job/plugins_nuxeo-customer-project-sample-master/.svg?style=flat-square)](https://qa.nuxeo.org/jenkins/job/master/job/plugins_nuxeo-customer-project-sample-master/)

This plugin aim to show how to build and structure a common customer project. It is continuously built from [Nuxeo CLI](https://doc.nuxeo.com/nxdoc/nuxeo-cli/) using the `bootstrap.sh` script.

## Structure

It decribes a simple project, with several modules:

```text
.
├── docker: Docker Parent Module
│   └── nuxeo-customer-project-sample-docker: Docker Image Module
├── nuxeo-customer-project-sample-core: Core Module
│   ├── nashorn_code_cache
│   │   └── HPgSpJxs_u615DWZjpnU-KW7AyQ_opt
│   └── src
│       ├── main
│       │   ├── java
│       │   └── resources
│       └── test
│           ├── java
│           └── resources
└── nuxeo-customer-project-sample-package: NOS Marketplace Package
    └── src
        └── main
            ├── assemble
            └── resources
```

### Core Module

A Core Module usually contains Java based development. Usually, you will find custom [Automation Operation](https://doc.nuxeo.com/nxdoc/content-automation-concepts/#operation), [Listeners](https://doc.nuxeo.com/nxdoc/events-and-listeners/#page-title), ...

Look at the [Nuxeo CLI](https://doc.nuxeo.com/nxdoc/nuxeo-cli/#page-title) documentation to discover what you can easily generate.
Full documentation about [Nuxeo Bundle](https://doc.nuxeo.com/nxdoc/runtime-and-component-model/).

### WebApp Module - NXP-29691 Temporarily Removed

A WebApp Module usually contains your Polymer Web Application as a standalone project to let you develop it as any other webapp.

Discover [Polymer Guide](https://doc.nuxeo.com/nxdoc/polymer-guide/#page-title) to help you starting a new project.

### Nuxeo Package

A Nuxeo Package usually contains installation instructions and optional constraints towards other packages (dependency, conflict). It is the easiest way to distribute a customer plugin, as it contains in one single ZIP file all the bundles, libraries, configuration properties and templates that are required to make the plugin work.

Full documentation about [Nuxeo Package](https://doc.nuxeo.com/nxdoc/creating-nuxeo-packages/).

## Building

> **Required Configuration**:
> Maven Repositories:
>
> *maven-internal*: Credentials Required, available on [packages.nuxeo.com](https://packages.nuxeo.com)
>
> ```xml
> <server>
>   <id>maven-internal</id>
>   <username>username</username>
>   <password>{9iw/tVNC+AgHtewewqeqidsa/3nWQFgKfeweqzGWpAyHIAuCull3IrrMOT8V112368sgw=}</password>
> </server>
> ```
>
> *nuxeo-studio*: NOS Studio Maven repository. Use account username and an [application token](https://doc.nuxeo.com/studio/token-management/) as password.
>
> ```xml
> <server>
>   <id>nuxeo-studio</id>
>   <username>username</username>
>   <password>{mXjWZLPWowewfa+aZIYrewfds+fsdfq6bRNYVLMn53iqO5cw5xEewqrFUrewr/Szpf}</password>
> </server>
> ```
>
> Can be automatically set using `nuxeo studio link` command from [Nuxeo CLI](https://github.com/nuxeo/nuxeo-cli).

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

[jira.nuxeo.com/browse/NXP](https://jira.nuxeo.com/browse/NXP)

## Licensing

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)

## About Nuxeo

Nuxeo dramatically improves how content-based applications are built, managed and deployed, making customers more agile, innovative and successful. Nuxeo provides a next generation, enterprise ready platform for building traditional and cutting-edge content oriented applications. Combining a powerful application development environment with SaaS-based tools and a modular architecture, the Nuxeo Platform and Products provide clear business value to some of the most recognizable brands including Verizon, Electronic Arts, Sharp, FICO, the U.S. Navy, and Boeing. Nuxeo is headquartered in New York and Paris. More information is available at www.nuxeo.com.
