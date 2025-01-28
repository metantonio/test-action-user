#!/bin/bash

# Arguments
VM1_CMD=$1  # e.g., "docker exec vm1"
VM2_CMD=$2  # e.g., "docker exec vm2"

# Function to fetch and parse users
fetch_users() {
  local CMD=$1
  echo "Fetching users from $CMD..."
  $CMD cat /etc/passwd | awk -F: '{print $1":"$3":"$4}' | grep -v "nobody"  # Exclude "nobody"
}

# Fetch users from both VMs
VM1_USERS=$(fetch_users "$VM1_CMD")
VM2_USERS=$(fetch_users "$VM2_CMD")

# Debug: Print fetched users
echo "Users on VM1: $VM1_USERS"
echo "Users on VM2: $VM2_USERS"

# Function to add missing users
add_user_if_missing() {
  local TARGET_CMD=$1
  local USERNAME=$2
  local USER_UID=$3  # Renamed from UID
  local USER_GID=$4  # Renamed from GID

  echo "Checking if user $USERNAME exists on target..."
  if ! $TARGET_CMD cat /etc/passwd | awk -F: '{print $1":"$3":"$4}' | grep -q "^$USERNAME:$USER_UID:$USER_GID$"; then
    echo "User $USERNAME (UID=$USER_UID, GID=$USER_GID) does not exist on target. Adding..."
    $TARGET_CMD useradd -u "$USER_UID" -g "$USER_GID" "$USERNAME" || echo "Failed to add $USERNAME on target."
  else
    echo "User $USERNAME already exists on target."
  fi
}

# Reconcile users from VM1 to VM2
echo "Reconciling users from VM1 to VM2..."
for user_entry in $VM1_USERS; do
  USERNAME=$(echo "$user_entry" | cut -d: -f1)
  USER_UID=$(echo "$user_entry" | cut -d: -f2)  # Renamed from UID
  USER_GID=$(echo "$user_entry" | cut -d: -f3)  # Renamed from GID
  add_user_if_missing "$VM2_CMD" "$USERNAME" "$USER_UID" "$USER_GID"
done

# Reconcile users from VM2 to VM1
echo "Reconciling users from VM2 to VM1..."
for user_entry in $VM2_USERS; do
  USERNAME=$(echo "$user_entry" | cut -d: -f1)
  USER_UID=$(echo "$user_entry" | cut -d: -f2)  # Renamed from UID
  USER_GID=$(echo "$user_entry" | cut -d: -f3)  # Renamed from GID
  add_user_if_missing "$VM1_CMD" "$USERNAME" "$USER_UID" "$USER_GID"
done

echo "User synchronization completed successfully!"
