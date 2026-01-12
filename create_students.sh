# Interactive Provisioning Loop
echo "Enter student names one by one (type 'done' when finished):"
while true; do
    read -p "Student Name: " S
    if [[ "$S" == "done" ]]; then break; fi
    if [[ -z "$S" ]]; then continue; fi

    # Create directory structure
    mkdir -p /data/home/test1/students/$S/{bin,envs,projects,.local,.cache}
    chmod 700 /data/home/test1/students/$S
    
    # Symlink Whitelisted Tools
    # Note: Using absolute paths for symlinks to ensure they work inside the jail
    ln -sf /usr/bin/python3 /data/home/test1/students/$S/bin/python3
    ln -sf /usr/bin/pip3 /data/home/test1/students/$S/bin/pip
    ln -sf /usr/bin/nvidia-smi /data/home/test1/students/$S/bin/nvidia-smi
    ln -sf /usr/bin/ls /data/home/test1/students/$S/bin/ls
    ln -sf /usr/bin/nano /data/home/test1/students/$S/bin/nano
    ln -sf /usr/bin/sbatch /data/home/test1/students/$S/bin/sbatch
    ln -sf /usr/bin/squeue /data/home/test1/students/$S/bin/squeue
    
    echo "Successfully provisioned environment for $S"
done
