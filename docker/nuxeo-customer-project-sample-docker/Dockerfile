# vim:set ft=dockerfile:
ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG VERSION
ARG SCM_REF
ARG BUILD_TAG
ARG CLID
ARG PACKAGES

LABEL org.nuxeo.explorer.version=${VERSION}
LABEL org.nuxeo.explorer.scm-ref=${SCM_REF}
LABEL org.nuxeo.explorer.build-tag=${BUILD_TAG}

COPY --chown=900:0 target/nuxeo-customer-project-sample-package-*.zip /local-packages/nuxeo-customer-project-sample-package.zip
# Workaround of above permission issues, otherwise we can't clean the package once installed
USER root
RUN /install-local-packages.sh /local-packages
RUN /install-packages.sh --clid ${CLID} ${PACKAGES}
RUN chown -R 900:0 ${NUXEO_HOME} \
  && chmod -R g+rwX ${NUXEO_HOME}
USER 900
