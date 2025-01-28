#!/bin/bash

YML_FILE=$1
VM1_HOST=$2
VM2_HOST=$3

# HOSTS=("192.168.1.100" "192.168.1.101") # IPs of virtual machines
HOSTS=("$VM1_HOST" "$VM2_HOST") # Added Host dinamycally from repository secret keys 

LDAP_CONFIG_FILE="/etc/ldap/slapd.conf" # LDAP path (i assume it is the same path for both machines)

# Read YML (requieres yq installed)
if ! command -v yq &>/dev/null; then
  echo "The command 'yq' doesn't exist. Install 'yq' before continue"
  exit 1
fi

for user in $(yq eval '.users[] | .username' "$YML_FILE"); do
  UID=$(yq eval ".users[] | select(.username==\"$user\") | .uid" "$YML_FILE")
  GID=$(yq eval ".users[] | select(.username==\"$user\") | .gid" "$YML_FILE")

  for host in "${HOSTS[@]}"; do
    echo "Verifying user $user in $host..."

    ssh user@$host "id $user" &>/dev/null
    if [[ $? -ne 0 ]]; then
      echo "The user $user doesn't exist in $host. Setting up the LDAP..."
      ssh user@$host <<EOF
sudo ldapadd -x -D "cn=admin,dc=example,dc=com" -w password <<EOL
dn: uid=$user,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
cn: $user
sn: $user
uid: $user
uidNumber: $UID
gidNumber: $GID
homeDirectory: /home/$user
EOL
EOF
    else
      echo "User $user already exist in $host."
    fi
  done
done
