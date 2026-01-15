#!/bin/bash
# gatekeeper.sh
# Usage: ./gatekeeper.sh <student_name>

STUDENT_NAME=$1

# 1. Validation
if [ -z "$STUDENT_NAME" ]; then 
    echo "Unauthorized: Identity not provided."
    exit 1 
fi

REAL_PROF_HOME=$HOME
WORKSPACE="$REAL_PROF_HOME/students/$STUDENT_NAME"

# 2. Critical Environment Spoofing
# By changing HOME, tools like Git, Pip, and SSH will look here for config files.
export HOME="$WORKSPACE"
export TMPDIR="$WORKSPACE/.cache/tmp"

# 3. AI Research Optimizations
# Unset DISPLAY to force 'headless' mode (prevents matplotlib/cv2 crashes)
unset DISPLAY

# Isolate heavy AI model caches so they don't fill the global partition
export TRANSFORMERS_CACHE="$WORKSPACE/.cache/huggingface"
export HF_HOME="$WORKSPACE/.cache/huggingface"
export TORCH_HOME="$WORKSPACE/.cache/torch"
export PIP_CACHE_DIR="$WORKSPACE/.cache/pip"

# 4. Path Configuration
# Add the local user base first, then the workspace bin, then system paths.
export PYTHONUSERBASE="$WORKSPACE/.local"
export PATH="$WORKSPACE/bin:$PYTHONUSERBASE/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/cuda/bin"

# 5. Access the Workspace
if cd "$WORKSPACE"; then
    echo "-----------------------------------------------------"
    echo "   Welcome to the IT Department ($STUDENT_NAME)"
    echo "-----------------------------------------------------"
    echo " * Workspace: $PWD"
    echo " * Git: Use HTTPS with PAT. Credentials are saved locally."
    echo "-----------------------------------------------------"

    # Source the security profile (navigation locks)
    if [ -f "$WORKSPACE/.bash_profile" ]; then
        source "$WORKSPACE/.bash_profile"
    fi
else
    echo "Error: Could not access workspace $WORKSPACE"
    exit 1
fi

# 6. Launch the Shell
exec /bin/bash --login