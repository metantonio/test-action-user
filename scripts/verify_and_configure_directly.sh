#!/bin/bash

YML_FILE=$1
VM1_HOST=$2
VM2_HOST=$3

HOSTS=("$VM1_HOST" "$VM2_HOST")

# Ensure the YAML file exists
if [[ ! -f "$YML_FILE" ]]; then
  echo "Error: YAML file $YML_FILE does not exist."
  exit 1
fi

# Install yq if it's not available (on each host)
for host in "${HOSTS[@]}"; do
  ssh -o StrictHostKeyChecking=no user@$host "command -v yq >/dev/null || sudo yum install -y epel-release && sudo yum install -y yq"
done

# Process each user from the YAML file
for user in $(yq eval '.users[].username' "$YML_FILE"); do
  UID=$(yq eval ".users[] | select(.username==\"$user\") | .uid" "$YML_FILE")
  GID=$(yq eval ".users[] | select(.username==\"$user\") | .gid" "$YML_FILE")

  echo "Checking user $user with UID=$UID and GID=$GID..."

  # Check user on both hosts
  for host in "${HOSTS[@]}"; do
    ssh -o StrictHostKeyChecking=no user@$host <<EOF
if id "$user" >/dev/null 2>&1; then
  EXISTING_UID=\$(id -u "$user")
  EXISTING_GID=\$(id -g "$user")

  if [[ "\$EXISTING_UID" -ne "$UID" || "\$EXISTING_GID" -ne "$GID" ]]; then
    echo "User $user exists on $host but with mismatched UID/GID. Updating..."
    sudo usermod -u $UID -g $GID "$user"
  else
    echo "User $user exists on $host with matching UID/GID."
  fi
else
  echo "User $user does not exist on $host. Creating..."
  sudo groupadd -g $GID "$user" || echo "Group $user already exists."
  sudo useradd -u $UID -g $GID -m "$user"
fi
EOF
  done
done
