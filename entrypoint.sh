#!/usr/bin/env bash

if [ "$#" -ne 0 ]; then
  "$@" # Ensures that we always have a shell. exec "$@" works when we are passed `/bin/bash -c "example"`, but not just `example`; the latter will
       # bypass the easy_infra shims because it doesn't have a BASH_ENV equivalent
  exit $?
fi

set -o nounset
set -o pipefail
# Don't turn on errexit to ensure we see the logs from failed ansible-playbooks attempts
#set -o errexit

# Setup ansible prereqs
DEFAULT_USER="$(awk -F: '$3 == 1000 {print $1}' < /host/etc/passwd)"
if [ -z "${HOST_USER:-}" ]; then
  HOST_USER="${DEFAULT_USER:-ec2-user}"
fi
HOST_HOME_DIR="/host/home/${HOST_USER}"
KEY_FILE="${HOST_HOME_DIR}/.ssh/ansible_key"
LOG_DIR="${HOST_HOME_DIR}/logs"
LOG_FILE="${LOG_DIR}/entrypoint.log"
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
# This is the desired UID/GID on the host
chown -R 1000:1000 "${LOG_DIR}"
KNOWN_HOSTS="${HOST_HOME_DIR}/.ssh/known_hosts"

if [[ -s "${KEY_FILE}" ]]; then
  echo "${KEY_FILE} already exists! Skipping SSH key setup..."
  echo "See ${LOG_FILE} for previous configuration details"
else
  SSH_PASS=""
  echo "Generated passphrase: ${SSH_PASS:-empty}" >> "${LOG_FILE}"
  ssh-keygen -N "${SSH_PASS}" -C "Ansible key" -f "${KEY_FILE}" | tee -a "${LOG_FILE}"

  AUTHORIZED_KEYS="${HOST_HOME_DIR}/.ssh/authorized_keys"
  cat "${KEY_FILE}.pub" >> "${AUTHORIZED_KEYS}"
  echo "Updated ${AUTHORIZED_KEYS}" | tee -a "${LOG_FILE}"

  ssh-keyscan localhost 2>/dev/null >> "${KNOWN_HOSTS}"
  echo "Updated ${KNOWN_HOSTS}" | tee -a "${LOG_FILE}"
fi

# Use a custom location for the known_hosts file based on how we've mounted the host filesystem
export ANSIBLE_SSH_ARGS="-o UserKnownHostsFile=${KNOWN_HOSTS}"
ansible-playbook ${ANSIBLE_CUSTOM_ARGS:-} -e 'ansible_python_interpreter=/usr/bin/python3' --inventory localhost, --user "${HOST_USER}" --private-key="${KEY_FILE}" /etc/app/container-security-101.yml | tee -a "${LOG_FILE}"
