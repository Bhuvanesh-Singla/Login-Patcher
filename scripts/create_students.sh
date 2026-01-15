#!/bin/bash
# create_students.sh

# --- 1. Security & Setup ---
PROF_HOME=$HOME
KEY_DIR="$PROF_HOME/incoming_keys"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "--- Student Onboarding Automation ---"

for KEY_FILE in "$KEY_DIR"/*.pub; do
    S=$(basename "$KEY_FILE" .pub)
    
    if [ ! -f "$KEY_FILE" ]; then
        echo "No .pub files found in $KEY_DIR"
        break
    fi

    echo "Processing Student: $S"

    # --- 2. Create Directory Structure ---
    STUDENT_ROOT="$PROF_HOME/students/$S"
    # Create standard folders plus AI cache folders
    mkdir -p "$STUDENT_ROOT"/{bin,envs,projects,.local,.cache/tmp,.cache/huggingface,.cache/torch}
    chmod 700 "$STUDENT_ROOT"
    
    # --- 3. Whitelist Tools (Symlinks) ---
    # Added: sbatch, squeue, scancel (Raw system commands)
    # Added: nvcc, gcc, make, g++ (For AI library compilation)
    TARGET_TOOLS="python3 nvidia-smi ls nano vim cp mv rm mkdir grep awk sed cat tail head tar gzip unzip git nvcc gcc g++ make cmake sbatch squeue scancel scontrol"
    
    for tool in $TARGET_TOOLS; do
        # Try finding the tool in common locations
        TOOL_PATH=$(which $tool 2>/dev/null)
        if [ -n "$TOOL_PATH" ]; then
            ln -sf "$TOOL_PATH" "$STUDENT_ROOT/bin/$tool"
        else
            echo "Warning: Tool '$tool' not found on host, skipping."
        fi
    done

    # --- 4. Custom Wrappers ---

    # A. PIP Wrapper (Forces local install)
    # This is still needed to prevent students from breaking global python
    cat << 'EOF' > "$STUDENT_ROOT/bin/pip"
#!/bin/bash
exec /usr/bin/python3 -m pip install --user --no-warn-script-location "$@"
EOF
    chmod +x "$STUDENT_ROOT/bin/pip"

    # --- 5. Configuration Files ---

    # A. Git PAT Configuration
    # Pre-configure Git to store credentials in the student's folder
    cat << EOF > "$STUDENT_ROOT/.gitconfig"
[credential]
    helper = store --file $STUDENT_ROOT/.git-credentials
[user]
    # Optional: You can force a blank name/email or let them set it locally
EOF

    # B. Navigation Lock (.bash_profile)
    cat << 'EOF' > "$STUDENT_ROOT/.bash_profile"
# Override 'cd' to prevent leaving the workspace
function cd() {
    if [ -z "$1" ]; then
        builtin cd "$HOME"
        return
    fi
    target=$(realpath -m "$1")
    if [[ "$target" == "$HOME"* ]]; then
        builtin cd "$target"
    else
        echo "Access Denied: Stay in your workspace."
    fi
}
export -f cd
EOF

    # --- 6. SSH Access Grant ---
    PUB_KEY=$(cat "$KEY_FILE")
    # We check for the key string to avoid duplicates
    if ! grep -Fq "$PUB_KEY" "$PROF_HOME/.ssh/authorized_keys"; then
        echo "command=\"$PROF_HOME/gatekeeper.sh $S\",no-X11-forwarding $PUB_KEY" >> "$PROF_HOME/.ssh/authorized_keys"
        echo "Success: $S setup complete."
    else
        echo "Skip: $S key already authorized."
    fi
done