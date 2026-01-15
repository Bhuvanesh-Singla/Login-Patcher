#!/bin/bash
# create_students.sh

# --- 1. Security & Setup ---
PROF_HOME=$HOME
KEY_DIR="$PROF_HOME/incoming_keys"


# --- PREP: Get pip installer (Run once by Prof) ---
GET_PIP_SCRIPT="$PROF_HOME/get-pip.py"

if [ ! -f "$GET_PIP_SCRIPT" ]; then
    echo "System Check: Downloading get-pip.py..."
    if command -v curl >/dev/null 2>&1; then
        curl -sSL https://bootstrap.pypa.io/get-pip.py -o "$GET_PIP_SCRIPT"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$GET_PIP_SCRIPT" https://bootstrap.pypa.io/get-pip.py
    else
        echo "Error: Neither curl nor wget found. Cannot download get-pip.py"
        exit 1
    fi
fi

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
    mkdir -p "$STUDENT_ROOT"/{bin,envs,projects,.local,.config/pip,.cache/tmp,.cache/huggingface,.cache/torch}
    chmod 700 "$STUDENT_ROOT"
    
    # --- 3. Whitelist Tools (Symlinks) ---
    TARGET_TOOLS="python3 nvidia-smi ls nano vim cp mv rm mkdir grep awk sed cat tail head tar gzip unzip git nvcc gcc g++ make cmake sbatch squeue scancel scontrol"
    
    for tool in $TARGET_TOOLS; do
        TOOL_PATH=$(which $tool 2>/dev/null)
        if [ -n "$TOOL_PATH" ]; then
            ln -sf "$TOOL_PATH" "$STUDENT_ROOT/bin/$tool"
        else
            echo "Warning: Tool '$tool' not found on host, skipping."
        fi
    done

    # --- 4. Install PIP Locally ---
    echo "  > Installing isolated pip..."
    export PYTHONUSERBASE="$STUDENT_ROOT/.local"
    /usr/bin/python3 "$GET_PIP_SCRIPT" --user --no-warn-script-location >/dev/null 2>&1
    unset PYTHONUSERBASE

    # --- FIXED PIP SETUP ---
    
    # A. The Wrapper (Pass-through only)
    # This ensures 'pip' command works even if not in path, but doesn't force 'install'
    cat << 'EOF' > "$STUDENT_ROOT/bin/pip"
#!/bin/bash
exec /usr/bin/python3 -m pip "$@"
EOF
    chmod +x "$STUDENT_ROOT/bin/pip"

    # B. The Config (The Clean Fix)
    # We use a standard pip.conf to enforce user installs. 
    # This allows 'pip list' and 'pip --version' to work while still protecting the system.
    cat << EOF > "$STUDENT_ROOT/.config/pip/pip.conf"
[global]
user = true
no-warn-script-location = false
EOF

    # --- 5. Configuration Files ---

    # A. Git PAT Configuration
    cat << EOF > "$STUDENT_ROOT/.gitconfig"
[credential]
    helper = store --file $STUDENT_ROOT/.git-credentials
[user]
    # Optional: Leave blank
EOF

    # B. Navigation Lock (.bash_profile)
    cat << 'EOF' > "$STUDENT_ROOT/.bash_profile"
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

    # C. Student Documentation (README)
    cat << 'EOF' > "$STUDENT_ROOT/README.txt"
WELCOME TO YOUR AI LAB WORKSPACE
----------------------------------------------------------------
1. FILES: Everything must stay in this folder. You cannot cd outside.
2. PYTHON: 'pip install <package>' works automatically (installs locally).
   - 'pip list', 'pip --version' now work correctly.
3. GIT: Use HTTPS with your Personal Access Token (PAT).
4. JOBS: Use 'sbatch', 'squeue', 'scancel'.
----------------------------------------------------------------
EOF

    # --- 6. SSH Access Grant ---
    PUB_KEY=$(cat "$KEY_FILE")
    if ! grep -Fq "$PUB_KEY" "$PROF_HOME/.ssh/authorized_keys"; then
        echo "command=\"$PROF_HOME/gatekeeper.sh $S\",no-X11-forwarding $PUB_KEY" >> "$PROF_HOME/.ssh/authorized_keys"
        echo "  > Success: Access granted."
    else
        echo "  > Skip: Key already authorized."
    fi
done