# Login-Patcher
A patch that enables secure student access to the departmental GPU server without requiring professors to share personal login credentials.

## Instructions for Professors
1. Clone the repository:
   ```bash
   git clone https://github.com/Bhuvanesh-Singla/Login-Patcher.git
    ```
2. Navigate to the cloned directory:
   ```bash
   cd Login-Patcher
   ```
3. Copy the gatekeeper script to your home directory and make it executable:
    ```bash
        cp scripts/gatekeeper.sh ~/gatekeeper.sh
        chmod +x ~/gatekeeper.sh
    ```
4. Create the folder in home directory where students will send their public keys:
   ```bash
        mkdir -p ~/incoming_keys
    ```
5. Onboard your students by sharing the [following](#instructions-for-students) instructions with them.
6. Put the .pub files received from students into the `incoming_keys` folder.
7. Convert the create students script to executable:
   ```bash
        chmod +x ~/Login-Patcher/scripts/create_students.sh
    ```
8. Run the ``create_students.sh`` script to add students to the server:
   ```bash
        ./scripts/create_students.sh
    ```

## Instructions for Students
1. Generate an SSH key pair if you don't already have one:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/<student_name>
   ```
   This creates a public key (`~/.ssh/<student_name>.pub`) and a private key (`~/.ssh/<student_name>`).
   Keep your private key secure and do not share it with anyone.
2. Send your public key to the professor via email.
3. To access the GPU server, use the following command:
   ```bash
   ssh -i ~/.ssh/<student_name> <professor_username>@<gpu_server_address> 
    ```
    Replace `<student_name>`, `<professor_username>`, and `<gpu_server_address>` with your actual student name, professor's username, and the GPU server's address respectively.

## Administrative Troubleshooting

Administrators only need to intervene if the SSH key authentication fails or SELinux blocks the non-standard paths.

### Fix 1: Permissions (The SSH Daemon Check)

SSH will refuse keys if permissions are too loose.

```
sudo chown -R <professor_username>:<professor_username> /home/<professor_username>
sudo chmod 755 /home/<professor_username>
sudo chmod 700 /home/<professor_username>/.ssh
sudo chmod 600 /home/<professor_username>/.ssh/authorized_keys
```

### Fix 2: SELinux Contexts (Rocky Specific)

If students are asked for a password despite having keys, the SELinux label is likely wrong.

```
sudo restorecon -Rv /home/<professor_username>/.ssh
```
