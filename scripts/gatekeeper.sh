#!/bin/bash
STUDENT_NAME=$1

if [ -z "$STUDENT_NAME" ]; then 
    echo "Unauthorized: Identity not provided."
    exit 1 
fi

PROF_HOME=$HOME
WORKSPACE="$PROF_HOME/students/$STUDENT_NAME"

# --- LIBRARY ISOLATION ---
export PYTHONUSERBASE="$WORKSPACE/.local"
export PIP_CACHE_DIR="$WORKSPACE/.cache/pip"
export JUPYTER_RUNTIME_DIR="$WORKSPACE/.local/share/jupyter/runtime"
export JUPYTER_DATA_DIR="$WORKSPACE/.local/share/jupyter"
export PATH="$WORKSPACE/bin:$PYTHONUSERBASE/bin:/usr/local/bin:/usr/bin:/bin"

if cd "$WORKSPACE"; then
    echo "--- Welcome to the HPC AI Lab ($STUDENT_NAME) ---"
    echo "Workspace: $PWD"
    echo "To install libraries use: pip install --user <package>"
else
    echo "Error: Could not access workspace $WORKSPACE"
    exit 1
fi

exec /bin/bash --restricted --login
