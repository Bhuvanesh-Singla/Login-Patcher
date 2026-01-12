# 1. Initialize SSH security files if they don't exist
#!/bin/bash
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 2. Run the Onboarding Loop
PROF_HOME=$HOME
KEY_DIR="$PROF_HOME/incoming_keys" # Folder where you put student1.pub, etc.

echo "--- Student Onboarding Automation ---"
echo "Looking for public keys in $KEY_DIR"

for KEY_FILE in "$KEY_DIR"/*.pub; do
    # Get student name from filename (e.g., student1.pub -> student1)
    S=$(basename "$KEY_FILE" .pub)
    
    if [ ! -f "$KEY_FILE" ]; then
        echo "No .pub files found in $KEY_DIR"
        break
    fi

    # Create directory structure
    mkdir -p "$PROF_HOME/students/$S"/{bin,envs,projects,.local,.cache}
    chmod 700 "$PROF_HOME/students/$S"
    
    # Symlink Whitelisted Tools
    ln -sf /usr/bin/python3 "$PROF_HOME/students/$S/bin/python3"
    ln -sf /usr/bin/pip3 "$PROF_HOME/students/$S/bin/pip"
    ln -sf /usr/bin/nvidia-smi "$PROF_HOME/students/$S/bin/nvidia-smi"
    ln -sf /usr/bin/ls "$PROF_HOME/students/$S/bin/ls"
    ln -sf /usr/bin/nano "$PROF_HOME/students/$S/bin/nano"
    ln -sf /usr/bin/sbatch "$PROF_HOME/students/$S/bin/sbatch"
    ln -sf /usr/bin/squeue "$PROF_HOME/students/$S/bin/squeue"
    
    # Add key to authorized_keys with forced-command jail
    PUB_KEY=$(cat "$KEY_FILE")
    # Check if key is already present to avoid duplicates
    if ! grep -Fq "$PUB_KEY" "$PROF_HOME/.ssh/authorized_keys"; then
        echo "command=\"$PROF_HOME/gatekeeper.sh $S\",no-X11-forwarding $PUB_KEY" >> "$PROF_HOME/.ssh/authorized_keys"
        echo "Provisioned workspace and SSH access for: $S"
    else
        echo "Skip: $S already has access in authorized_keys"
    fi
done
