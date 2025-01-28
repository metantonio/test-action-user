#!/bin/bash

# Arguments
VM1_CMD=$1  # e.g., "docker exec vm1"
VM2_CMD=$2  # e.g., "docker exec vm2"

# Fetch users from the first VM
echo "Fetching users from VM1..."
VM1_USERS=$($VM1_CMD cat /etc/passwd | awk -F: '{print $1":"$3":"$4}')
echo "$VM1_USERS"

# Fetch users from the second VM
echo "Fetching users from VM2..."
VM2_USERS=$($VM2_CMD cat /etc/passwd | awk -F: '{print $1":"$3":"$4}')
echo "$VM2_USERS"

# Reconcile users
echo "Reconciling users between VM1 and VM2..."
for user_entry in $VM1_USERS; do
  USERNAME=$(echo "$user_entry" | cut -d: -f1)
  UID=$(echo "$user_entry" | cut -d: -f2)
  GID=$(echo "$user_entry" | cut -d: -f3)

  # Check if the user exists on VM2
  if ! echo "$VM2_USERS" | grep -q "^$USERNAME:$UID:$GID$"; then
    echo "User $USERNAME (UID=$UID, GID=$GID) does not exist on VM2. Adding..."
    $VM2_CMD useradd -u "$UID" -g "$GID" "$USERNAME"
  fi
done

for user_entry in $VM2_USERS; do
  USERNAME=$(echo "$user_entry" | cut -d: -f1)
  UID=$(echo "$user_entry" | cut -d: -f2)
  GID=$(echo "$user_entry" | cut -d: -f3)

  # Check if the user exists on VM1
  if ! echo "$VM1_USERS" | grep -q "^$USERNAME:$UID:$GID$"; then
    echo "User $USERNAME (UID=$UID, GID=$GID) does not exist on VM1. Adding..."
    $VM1_CMD useradd -u "$UID" -g "$GID" "$USERNAME"
  fi
done

echo "User synchronization completed successfully!"
