# syntax=docker/dockerfile:1

ARG EASY_INFRA_VERSION=2024.04.01
# TARGETPLATFORM is special cased by docker and doesn't need an initial ARG; if you plan to use it repeatedly you must add ARG TARGETPLATFORM between uses
# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
FROM --platform=$TARGETPLATFORM seiso/easy_infra:${EASY_INFRA_VERSION}-ansible AS base
# Since we use TARGETARCH below, we need to re-scope it
ARG TARGETARCH

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ARG VERSION
ARG COMMIT_HASH

LABEL org.opencontainers.image.title="Container Security 101 lab setup"
LABEL org.opencontainers.image.description="Setup Jon Zeolla's Container Security 101 lab"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.vendor="Jon Zeolla"
LABEL org.opencontainers.image.url="https://jonzeolla.com"
LABEL org.opencontainers.image.source="https://github.com/JonZeolla/container-security-101"
LABEL org.opencontainers.image.revision="${COMMIT_HASH}"
LABEL org.opencontainers.image.licenses="NONE"

# Configure easy_infra
ARG SILENT="true"
ENV SILENT="${SILENT}"

COPY lab-resources /etc/app/lab-resources
COPY requirements.yml /etc/app/requirements.yml

# A privileged user is necessary in order to build and to run the entrypoint
# hadolint ignore=DL3002
USER root
RUN ansible-galaxy collection build /etc/app/lab-resources/ansible/jonzeolla/labs \
 && ansible-galaxy collection install ./jonzeolla-labs-*.tar.gz \
 && rm ./jonzeolla-labs-*.tar.gz \
 && ansible-galaxy collection install -r /etc/app/requirements.yml \
 && curl https://get.docker.com -o get-docker.sh \
 # Avoid setting the VERSION env var during get-docker.sh
 && unset VERSION \
 && bash ./get-docker.sh \
 && rm get-docker.sh

ENV ANSIBLE_ROLES_PATH="${ANSIBLE_ROLES_PATH}:/etc/app/ansible/roles/"
COPY ansible/roles/ /etc/app/ansible/roles/

COPY container-security-101.yml /etc/app/container-security-101.yml
COPY vars /etc/app/vars

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
