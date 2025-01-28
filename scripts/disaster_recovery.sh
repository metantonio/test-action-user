#!/bin/bash

VM1_HOST=$1
VM2_HOST=$2

# Function to get all users with their UID and GID from a machine
get_users_from_host() {
  local host=$1
  ssh -o StrictHostKeyChecking=no user@$host "awk -F: '\$3 >= 1000 && \$3 < 65534 {print \$1,\$3,\$4}' /etc/passwd"
}

# Function to create or update a user on a machine
sync_user_to_host() {
  local user=$1
  local uid=$2
  local gid=$3
  local host=$4

  ssh -o StrictHostKeyChecking=no user@$host <<EOF
if id "$user" >/dev/null 2>&1; then
  EXISTING_UID=\$(id -u "$user")
  EXISTING_GID=\$(id -g "$user")

  if [[ "\$EXISTING_UID" -ne "$uid" || "\$EXISTING_GID" -ne "$gid" ]]; then
    echo "Updating user $user on $host with UID=$uid and GID=$gid..."
    sudo usermod -u $uid -g $gid "$user"
  else
    echo "User $user already exists on $host with matching UID/GID."
  fi
else
  echo "Creating user $user on $host with UID=$uid and GID=$gid..."
  sudo groupadd -g $gid "$user" || echo "Group $user already exists."
  sudo useradd -u $uid -g $gid -m "$user"
fi
EOF
}

# Fetch users from both machines
echo "Fetching users from $VM1_HOST..."
users_vm1=$(get_users_from_host $VM1_HOST)

echo "Fetching users from $VM2_HOST..."
users_vm2=$(get_users_from_host $VM2_HOST)

# Combine users from both machines, ensuring no duplicates
echo "Reconciling users between $VM1_HOST and $VM2_HOST..."
all_users=$(echo -e "$users_vm1\n$users_vm2" | sort -u)

# Sync all users to both machines
echo "$all_users" | while read -r user uid gid; do
  echo "Processing user $user (UID=$uid, GID=$gid)..."
  
  # Sync user to Machine 1
  echo "Ensuring $user exists on $VM1_HOST..."
  sync_user_to_host "$user" "$uid" "$gid" "$VM1_HOST"
  
  # Sync user to Machine 2
  echo "Ensuring $user exists on $VM2_HOST..."
  sync_user_to_host "$user" "$uid" "$gid" "$VM2_HOST"
done

echo "User synchronization completed successfully!"
