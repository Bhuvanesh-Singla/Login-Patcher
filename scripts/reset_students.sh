#!/bin/bash
# reset_workspaces.sh
# Usage: ./reset_workspaces.sh <student1_name> [student2_name ...]
# Example: ./reset_workspaces.sh john_doe

PROF_HOME=$HOME

if [ $# -eq 0 ]; then
    echo "Usage: $0 <student_name> [student_name ...]"
    exit 1
fi

# Confirm action
echo "WARNING: This will WIPE ALL DATA inside the workspaces of: $@"
read -p "Are you sure? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

for S in "$@"; do
    echo "-----------------------------------"
    echo "Resetting Workspace: $S"
    STUDENT_ROOT="$PROF_HOME/students/$S"

    # Check if student exists (we check if folder exists, or at least intended path)
    # If folder is missing, we treat it as a "repair" operation.
    
    echo "  > Wiping current data..."
    rm -rf "$STUDENT_ROOT"

    echo "  > Re-provisioning environment..."

    # --- RE-PROVISIONING LOGIC (Synced with create_students.sh) ---

    # 1. Create Directory Structure
    mkdir -p "$STUDENT_ROOT"/{bin,envs,projects,.local,.cache/tmp,.cache/huggingface,.cache/torch}
    chmod 700 "$STUDENT_ROOT"
    
    # 2. Whitelist Tools (Conda Edition)
    TARGET_TOOLS="nvidia-smi ls nano vim cp mv rm mkdir grep awk sed cat tail head tar gzip unzip git nvcc gcc g++ make cmake sbatch squeue scancel scontrol"
    
    for tool in $TARGET_TOOLS; do
        TOOL_PATH=$(which $tool 2>/dev/null)
        if [ -n "$TOOL_PATH" ]; then
            ln -sf "$TOOL_PATH" "$STUDENT_ROOT/bin/$tool"
        fi
    done

    # 3. Configuration Files

    # Git Config
    cat << EOF > "$STUDENT_ROOT/.gitconfig"
[credential]
    helper = store --file $STUDENT_ROOT/.git-credentials
[user]
    # Optional: Leave blank
EOF

    # Navigation Lock (.bash_profile)
    cat << 'EOF' > "$STUDENT_ROOT/.bash_profile"
# 1. Load interactive settings (Conda usually writes to .bashrc)
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# 2. Override 'cd' to prevent leaving the workspace
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

    # README
    cat << 'EOF' > "$STUDENT_ROOT/README.txt"
WELCOME TO YOUR GPU WORKSPACE
----------------------------------------------------------------
1. FILES: Everything must stay in this folder. You cannot cd outside.
2. ENVIRONMENTS (Conda):
   - Initialize (Run once): 'conda init' -> Then log out and log back in.
   - Create:   'conda create -n myenv python=3.11'
   - Activate: 'conda activate myenv'
   - Install:  'conda install pytorch-gpu' OR 'pip install ...'
3. GIT: Use HTTPS with your Personal Access Token (PAT).
   (SFTP is NOT supported. Pull code via Git).
4. JOBS: Use 'sbatch', 'squeue', 'scancel'.
----------------------------------------------------------------
EOF

    echo "  [✓] Success: $S has been reset to factory settings."
done