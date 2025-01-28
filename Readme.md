# Test to verify users on 2 different virtual machines with linux red hat/ubuntu.

## Summary

- Input: users.yml -> List of user that needs to verify
- Action: Connect to machines to verify UID and GID
- Result: If user doesn't exist then configure the LDAP


## Considerations

You must have a secret key configured on this repository:

  - Settings > Secrets and variables > Actions.
  - Create a new secret named: `SSH_PRIVATE_KEY` and paste the secret key from your local machine


If you don't have any SSH key on your local linux based system, you must create one:

1) Generate a pair of SSH keys (public and private) with any string:
   
   ```bash
    ssh-keygen -t rsa -b 4096 -C "my_email@example.com"
   ```
