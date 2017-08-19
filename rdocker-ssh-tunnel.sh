#!/bin/bash
set -e

# use ssh port; allow to override
SSH_PORT=${SSH_PORT:-22}

re='^[0-9]+$'
if [[ $# -eq 0 || $1 == "-h" || $1 == "-help" ]]; then
    echo "Usage: rdocker [-h|-help] [user@]hostname [port] [cmd]"
    echo ""
    echo "    -h -help        print this message"
    echo "    user@hostname   ssh remote login address"
    echo "    port            local port used to forward the remote docker daemon, if not present a free random port will be used"
    echo "    cmd             when provided, it is the only command run on the remote host (no bash session is created)"
    echo "    SSH_PORT        set ssh port through environment variable (default: 22)"
    exit
fi

# use SSH_KEY environment variable to create key file, if not exists
ssh_key_file="$HOME/.ssh/id_rdocker"
if [[ ! -f "$ssh_key_file" ]]; then
  if [[ ! -z "${SSH_KEY}" ]]; then
    echo "SSH key passed through SSH_KEY environment variable: lenght check ${#SSH_KEY}"
    mkdir -p ~/.ssh
    if [[ ! -z "${SPLIT_CHAR}" ]]; then
      echo "${SSH_KEY}" | tr \'"${SPLIT_CHAR}"\' '\n' > "$ssh_key_file"
    else
      echo "${SSH_KEY}" > "$ssh_key_file"
    fi
    chmod 600 "$ssh_key_file"
  fi
else
  echo "Found $ssh_key_file file"
fi

#Extracting parameters
remote_host=${1}
if [[ $2 =~ $re ]]; then
    local_port=${2}
    command=${*:3} #third parameter and beyond
else
    command=${*:2} #second parameter and beyond
fi
control_path="$HOME/.rdocker-master-$(date +%s%N)"

#ssh "${remote_host}" -p ${SSH_PORT} -i "$ssh_key_file" -nNf -o "StrictHostKeyChecking no" -o ControlMaster=yes -o ControlPath="${control_path}" -o ControlPersist=yes

#ssh -i "$ssh_key_file" -fNL ${local_port}:localhost:${local_port} -p ${SSH_PORT} "${remote_host}" -o "StrictHostKeyChecking no"
ssh -i "$ssh_key_file" -p ${SSH_PORT} "${remote_host}" -o "StrictHostKeyChecking no"
#export DOCKER_HOST="tcp://localhost:${local_port}"

if [[ -n "$command" ]]; then
    bash -c "$command"
    exit_status=$?
fi