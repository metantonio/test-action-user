#!/bin/bash

VM1_HOST=$1
VM2_HOST=$2

# Function to get a list of users and their UID/GID from a host
get_users_from_host() {
  local host=$1
  ssh -o StrictHostKeyChecking=no user@$host "awk -F: '\$3 >= 1000 && \$3 < 65534 {print \$1,\$3,\$4}' /etc/passwd"
}

# Fetch users from VM1
echo "Fetching users from $VM1_HOST..."
users_vm1=$(get_users_from_host $VM1_HOST)

# Process each user from VM1
echo "$users_vm1" | while read -r user uid gid; do
  echo "Checking user $user (UID=$uid, GID=$gid) on $VM2_HOST..."

  # Check if the user exists on VM2
  ssh -o StrictHostKeyChecking=no user@$VM2_HOST <<EOF
if id "$user" >/dev/null 2>&1; then
  EXISTING_UID=\$(id -u "$user")
  EXISTING_GID=\$(id -g "$user")

  if [[ "\$EXISTING_UID" -ne "$uid" || "\$EXISTING_GID" -ne "$gid" ]]; then
    echo "User $user exists on $VM2_HOST but with mismatched UID/GID. Updating..."
    sudo usermod -u $uid -g $gid "$user"
  else
    echo "User $user exists on $VM2_HOST with matching UID/GID."
  fi
else
  echo "User $user does not exist on $VM2_HOST. Creating..."
  sudo groupadd -g $gid "$user" || echo "Group $user already exists."
  sudo useradd -u $uid -g $gid -m "$user"
fi
EOF
done
