# Nuxeo Final Project Samples

Two different "final" projects use cases with associated packages and docker images:
- final1: relies on "common" 1st level project, was copied from "vertical" 2nd level project on Studio side
- final2: relies on both "common" and "vertical" projects

Just to illustrate that this is also a packaging possibility, both packages are built using a common assembly.xml and
install.xml files.

Packaging also illustrates options for installation of the packages:
- final1 package sets the common package as a package dependency
- final2 package embeds/holds all dependencies needed for installation and does not depend on the common package

Note that dedicated common and vertical packages are needed to be referenced in the final studio projects
application definition too.

## Licensing

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)

## About Nuxeo

Nuxeo dramatically improves how content-based applications are built, managed and deployed, making customers more agile, innovative and successful. Nuxeo provides a next generation, enterprise ready platform for building traditional and cutting-edge content oriented applications. Combining a powerful application development environment with SaaS-based tools and a modular architecture, the Nuxeo Platform and Products provide clear business value to some of the most recognizable brands including Verizon, Electronic Arts, Sharp, FICO, the U.S. Navy, and Boeing. Nuxeo is headquartered in New York and Paris. More information is available at www.nuxeo.com.
