#!/bin/bash
# deboard_students.sh
# Usage: ./deboard_students.sh <student1_name> [student2_name ...]
# Example: ./deboard_students.sh john_doe jane_doe

PROF_HOME=$HOME
AUTH_KEYS="$PROF_HOME/.ssh/authorized_keys"

# Validate input
if [ $# -eq 0 ]; then
    echo "Usage: $0 <student_name> [student_name ...]"
    exit 1
fi

# Confirm action (Safety check)
echo "WARNING: This will PERMANENTLY DELETE data and REVOKE access for: $@"
read -p "Are you sure? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

for S in "$@"; do
    echo "-----------------------------------"
    echo "Processing Deboard: $S"

    STUDENT_ROOT="$PROF_HOME/students/$S"
    KEY_FILE="$PROF_HOME/incoming_keys/$S.pub"

    # 1. Revoke SSH Access
    if [ -f "$AUTH_KEYS" ]; then
        # We look for the line containing "gatekeeper.sh <student_name>"
        if grep -q "gatekeeper.sh $S" "$AUTH_KEYS"; then
            # Backup before modification
            cp "$AUTH_KEYS" "${AUTH_KEYS}.bak"
            
            # Remove the specific line
            grep -v "gatekeeper.sh $S" "$AUTH_KEYS" > "${AUTH_KEYS}.tmp" && mv "${AUTH_KEYS}.tmp" "$AUTH_KEYS"
            chmod 600 "$AUTH_KEYS"
            echo "SSH access revoked (removed from authorized_keys)."
        else
            echo "No SSH entry found for $S."
        fi
    else
        echo "authorized_keys file missing."
    fi

    # 2. Delete Workspace
    if [ -d "$STUDENT_ROOT" ]; then
        rm -rf "$STUDENT_ROOT"
        echo "Workspace directory deleted."
    else
        echo "Workspace not found ($STUDENT_ROOT)."
    fi

    # 3. Clean up Public Key (Optional)
    if [ -f "$KEY_FILE" ]; then
        rm "$KEY_FILE"
        echo "Public key file removed from incoming_keys."
    fi

    echo "Done with $S."
done