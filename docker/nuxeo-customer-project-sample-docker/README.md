nuxeo/nuxeo-customer-project-sample Docker Image
================================================

This module is responsible for building the customer project's Docker image.

**Requirements:**

- `NUXEO_CLID` environment variable contains `instance.clid` content while replacing `\n` carret return by `--`.

Locally, the image can be built with Maven:

```bash
# Using GNU sed
NUXEO_CLID=$(cat /my-env/instance.clid | sed -z 's/\n/--/g') mvn clean install

# Portable Version
NUXEO_CLID=$(cat /my-env/instance.clid | sed -e ':a' -e 'N;$!ba' -e 's/\n/--/') mvn clean install
```

On Jenkins X, skaffold takes care of building and testing the image.
