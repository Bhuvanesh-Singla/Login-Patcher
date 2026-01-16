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

# 4. Path Configuration (CONDA FIRST)
# We strictly follow the server instructions to prepend Conda paths.
# Priority: 
#   1. Conda (System Global)
#   2. Student's Local Bin (whitelisted symlinks)
#   3. Student's Pip User Base (if they use pip outside conda)
#   4. System Paths
CONDA_PATH="/data/apps/conda/bin"
CONDA_LIB="/data/apps/conda/lib"

export PYTHONUSERBASE="$WORKSPACE/.local"
export PATH="$CONDA_PATH:$WORKSPACE/bin:$PYTHONUSERBASE/bin:/usr/local/bin:/usr/bin:/bin"
export LD_LIBRARY_PATH="$CONDA_LIB:$LD_LIBRARY_PATH"

# 5. Access the Workspace
if cd "$WORKSPACE"; then
    echo "-----------------------------------------------------"
    echo "   Welcome to the GPU Server ($STUDENT_NAME)"
    echo "-----------------------------------------------------"
    echo " * Workspace: $PWD"
    echo " * Environment: Conda is available (/data/apps/conda)"
    echo " * Git: Use HTTPS with PAT. Credentials are saved locally."
    echo "-----------------------------------------------------"

    # Source .bashrc first (Important for 'conda activate' to work)
    if [ -f "$WORKSPACE/.bashrc" ]; then
        source "$WORKSPACE/.bashrc"
    fi

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