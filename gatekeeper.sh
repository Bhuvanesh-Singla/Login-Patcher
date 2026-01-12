#!/bin/bash
# Identifies the student via the first argument passed from authorized_keys
STUDENT_NAME=$1

if [ -z "$STUDENT_NAME" ]; then 
    echo "Unauthorized: Identity not provided."
    exit 1 
fi

# Path for your specific server configuration
WORKSPACE="/data/home/test1/students/$STUDENT_NAME"

# --- LIBRARY ISOLATION ---
# Redirects pip installs and python lookups to the student's subfolder
export PYTHONUSERBASE="$WORKSPACE/.local"
export PIP_CACHE_DIR="$WORKSPACE/.cache/pip"
export JUPYTER_RUNTIME_DIR="$WORKSPACE/.local/share/jupyter/runtime"
export JUPYTER_DATA_DIR="$WORKSPACE/.local/share/jupyter"

# Ensure student's bin and local python libs are in PATH
export PATH="$WORKSPACE/bin:$PYTHONUSERBASE/bin:/usr/local/bin:/usr/bin:/bin"

# Move to workspace
if cd "$WORKSPACE"; then
    echo "--- Welcome to the HPC AI Lab ($STUDENT_NAME) ---"
    echo "Workspace: $WORKSPACE"
    echo "To install libraries use: pip install --user <package>"
else
    echo "Error: Could not access workspace $WORKSPACE"
    exit 1
fi

# Launch Restricted Bash
# --restricted: prevents 'cd', setting PATH, or output redirection
# --login: ensures a clean environment
exec /bin/bash --restricted --login
