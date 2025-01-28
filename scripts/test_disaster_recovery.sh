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

# Function to add missing groups
add_group_if_missing() {
  local TARGET_CMD=$1
  local GROUP_ID=$2

  echo "Checking if group with GID=$GROUP_ID exists on target..."
  if ! $TARGET_CMD cat /etc/group | awk -F: '{print $3}' | grep -q "^$GROUP_ID$"; then
    echo "Group with GID=$GROUP_ID does not exist on target. Adding..."
    $TARGET_CMD groupadd -g "$GROUP_ID" "group_$GROUP_ID" || echo "Failed to add group with GID=$GROUP_ID."
  else
    echo "Group with GID=$GROUP_ID already exists on target."
  fi
}

# Function to add missing users
add_user_if_missing() {
  local TARGET_CMD=$1
  local USERNAME=$2
  local USER_UID=$3
  local USER_GID=$4

  # Ensure the group exists before adding the user
  add_group_if_missing "$TARGET_CMD" "$USER_GID"

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
  USER_UID=$(echo "$user_entry" | cut -d: -f2)
  USER_GID=$(echo "$user_entry" | cut -d: -f3)
  add_user_if_missing "$VM2_CMD" "$USERNAME" "$USER_UID" "$USER_GID"
done

# Reconcile users from VM2 to VM1
echo "Reconciling users from VM2 to VM1..."
for user_entry in $VM2_USERS; do
  USERNAME=$(echo "$user_entry" | cut -d: -f1)
  USER_UID=$(echo "$user_entry" | cut -d: -f2)
  USER_GID=$(echo "$user_entry" | cut -d: -f3)
  add_user_if_missing "$VM1_CMD" "$USERNAME" "$USER_UID" "$USER_GID"
done

echo "User synchronization completed successfully!"
