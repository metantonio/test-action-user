# Test to verify users on 2 different virtual machines with linux red hat/ubuntu.

## Summary

- Input: users.yml -> List of user that needs to verify
- Action: Connect to machines to verify UID and GID
- Result: If user doesn't exist then configure the LDAP


## Considerations

You must have a secret key configured on this repository:

  - Settings > Secrets and variables > Actions.
  - Create a new secret named: `SSH_PRIVATE_KEY` and paste the secret key from your local machine.
  - The user and IP used to connect to the virtual machines are secret keys too, named:
    - `VM1_HOST`
    - `VM2_HOST`




If you don't have any SSH key on your local linux based system, you must create one:

1) Generate a pair of SSH keys (public and private) with any string:
   
   ```bash
    ssh-keygen -t rsa -b 4096 -C "my_email@example.com"
   ```
2) It will ask for a path to save the new keys, to avoid overwrite another key, select a new filename. Example:

   ```bash
    /home/usuario/github-action-key
   ```

3) Leave the password in blank, just to avoid problems with the GitHub Actions Runner

4) You will see two new files:

   - Private key: `/home/usuario/github-action-key`
   - Public key: `/home/usuario/github-action-key.pub`

5) You will need to copy the `Public key`. Open the file to copy it at:

   ```bash
   cat /home/usuario/github-action-key.pub
   ```

6) The following process must be repeated  on your machines, in order to authorize access with the public keys:

  6.1) Access to you machines phisically or through SSH with:

  ```bash
  ssh user@<IP_O_HOSTNAME>
  ```

  6.2) Add the public key to the `~/.ssh/authorized_keys` file of the same user that you connected with SSH:

  ```bash
  echo "TU_CLAVE_PUBLICA" >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  ```

  6.3) Check if the SSH server has enabled the authentication with public keys in the file `/etc/ssh/sshd_config`, and check the following lines:

  ```bash
  PubkeyAuthentication yes
  AuthorizedKeysFile .ssh/authorized_keys
  ```

  6.4) Restart the SSH service:

  ```ssh
  sudo systemctl restart sshd
  ```


