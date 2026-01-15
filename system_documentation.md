# Login Patcher - System Documentation

## 1. System Overview

This system enables a single Linux user account (`prof`) to host multiple isolated "Student" environments. It is designed IT Department HPC Server where giving every student a full system account is not feasible.

### Core Philosophy

Instead of creating actual Linux users (which requires sudo/admin rights), we use:
- **SSH Forced Commands** - Restrict what commands students can execute
- **Environment Spoofing** - Create fake "home" directories for each student
- **Path Redirection** - Trap file operations within designated sub-directories

---

## 2. Architecture Diagram

```
[ Student's Laptop ]
       |
       | SSH Connection (Key-based)
       v
[ Server (User: prof) ]
       |
    (SSH Daemon checks authorized_keys)
       |
       +---> [ Match Found! ]
       |     Context: command="/home/prof/gatekeeper.sh studentA"
       |
       v
[ gatekeeper.sh ] (The Enforcer)
       | 1. Sets HOME = /home/prof/students/studentA
       | 2. Redirects Python/Pip/AI Caches to local folder
       | 3. Unsets DISPLAY (Headless mode)
       | 4. Spawns /bin/bash
       v
[ Student's Shell ]
       | "Welcome to your workspace"
       | (Restricted via .bash_profile logic, not rbash)
```

---

## 3. File Structure

The system relies on a strict directory hierarchy created inside the Professor's home:

```
/home/prof/
├── incoming_keys/           # Drop student public keys here (student1.pub)
├── gatekeeper.sh            # Runtime script (runs on every login)
├── create_students.sh       # Provisioning script (runs manually)
├── get-pip.py               # Auto-downloaded pip installer
└── students/                # The "Jail" root
    ├── student1/            # Student 1's "Fake Home"
    │   ├── bin/             # Symlinks to allowed tools
    │   ├── .local/          # Python libraries (pip install --user)
    │   ├── .cache/          # HuggingFace/Torch models (isolated)
    │   ├── .cache/huggingface/
    │   ├── .cache/torch/
    │   ├── .config/pip/     # pip.conf (force local install)
    │   ├── .gitconfig       # Local Git identity & credentials
    │   └── .bash_profile    # Overrides 'cd' to prevent escape
    └── student2/
        └── ...same structure...
```

---

## 4. Script Analysis: `create_students.sh` (The Provisioner)

**Purpose:** Reads SSH keys from `incoming_keys/` and builds the isolated file system for new students. It is idempotent (safe to run multiple times to update configurations).

### 4.1 Dependencies (get-pip.py)

- **What it does:** Checks if `get-pip.py` exists. If not, downloads it using `curl` or `wget`.
- **Why needed:** We need to give students a working pip even if the host server doesn't have it installed globally.

### 4.2 The Main Loop

Iterates through `*.pub` files in `incoming_keys/` and extracts the student name from the filename.

#### Step 1: Directory Construction

Creates the workspace skeleton for each student:
- `bin/` - Symlinks to approved tools
- `.local/` - Python packages directory
- `.cache/huggingface/` - HuggingFace model cache
- `.cache/torch/` - PyTorch model cache
- `.config/pip/` - Pip configuration
- `.ssh/` - SSH keys

**Reason:** AI libraries download GBs of data. Pre-creating these folders allows us to map environment variables, preventing the Professor's disk quota from being filled with shared cache data.

#### Step 2: Tool Whitelisting (Symlinking)

Iterates through approved tools and symlinks them from `/usr/bin` to `students/$S/bin/`:

```
python3, nvcc, git, sbatch, squeue, conda, nvtop, ...
```

**Logic:** When the student logs in, their `$PATH` checks the local `bin/` folder first, making these tools available.

#### Step 3: Pip Injection (The No-Sudo Fix)

```bash
export PYTHONUSERBASE="$WORKSPACE/.local"
python3 get-pip.py --user
```

**Result:** Installs a full pip binary and libraries into the student's folder without needing root access.

#### Step 4: Configuration Injection

**Pip Config (`pip.conf`)**
```ini
[global]
user = true
```
**Why:** Ensures `pip install X` behaves like `pip install --user X`. Prevents permission errors when students install libraries.

**Pip Wrapper (`bin/pip`)**
```bash
#!/bin/bash
/usr/bin/python3 -m pip "$@"
```
**Why:** Ensures the `pip` command is available in the path and uses the correct Python interpreter.

**Git Config**
```bash
git config --global credential.helper store
```
**Why:** Saves PAT tokens to the student's folder, preventing collision with the Professor's git credentials.

**Navigation Lock (`.bash_profile`)**
```bash
function cd() {
    if [[ "$1" == /* ]]; then
        # Absolute path check
        if [[ ! "$1" =~ ^$HOME ]]; then
            echo "Access denied: Cannot navigate outside workspace"
            return 1
        fi
    fi
    builtin cd "$@"
}
```
**Logic:** Overrides the `cd` command to check if the target path starts with `$HOME` (the workspace). If not, it blocks the command.

#### Step 5: SSH Access Grant

```bash
command="/home/prof/gatekeeper.sh student1",no-X11-forwarding <PUBKEY>
```

**What it does:** Appends the student's public key to `~/.ssh/authorized_keys` with a forced command.

**Security:** This is the most critical line. It ensures the user cannot bypass the `gatekeeper.sh` setup script.

---

## 5. Script Analysis: `gatekeeper.sh` (The Enforcer)

**Purpose:** Runs every time a student connects. It configures the session environment before spawning the interactive shell.

### 5.1 Identity Validation

```bash
STUDENT=$1
[ -z "$STUDENT" ] && exit 1
```

Checks if the student name is provided as an argument.

### 5.2 Environment Spoofing (The "Chroot-Lite")

```bash
export HOME="/home/prof/students/$STUDENT"
WORKSPACE="$HOME"
```

**Effect:** To the shell, `~` is now `/home/prof/students/student1`. Config files (`.bashrc`, `.ssh/`, `.gitconfig`) are looked up here. The student feels like they are in their own isolated machine.

### 5.3 AI Research Optimization

**Disable GUI forwarding:**
```bash
unset DISPLAY
```
**Why:** AI plotting libs (matplotlib) crash if they detect X11 forwarding but can't find a screen. Unsetting this forces them to save files instead of crashing.

**Cache Redirection:**
```bash
export TRANSFORMERS_CACHE="$WORKSPACE/.cache"
export HF_HOME="$WORKSPACE/.cache/huggingface"
export HF_DATASETS_CACHE="$WORKSPACE/.cache/huggingface/datasets"
export TORCH_HOME="$WORKSPACE/.cache/torch"
```
**Why:** Essential for HuggingFace/PyTorch users. Keeps 100GB+ model weights inside the student's quota, not the global system.

### 5.4 Path Construction

```bash
export PATH="$WORKSPACE/bin:$PYTHONUSERBASE/bin:/usr/local/cuda/bin:/usr/bin:/bin"
```

**Priority order:**
1. `workspace/bin/` - Whitelisted tools (symlinks)
2. `.local/bin/` - Tools installed by student via pip (e.g., jupyter, black)
3. System paths - Fallback to standard utilities

### 5.5 Handover to Shell

```bash
cd "$WORKSPACE"
source .bash_profile
exec /bin/bash --login
```

**Notes:**
- We use `exec` to replace the script process with Bash
- We use standard Bash (not `rbash`) to allow complex workflows (VS Code Remote, Conda, virtual environments)
- Safety relies on the "Fake Home" and `cd` function override, not shell restrictions

---

## 6. Frequently Asked Questions (FAQs)

### Q: Why not use `rbash` (Restricted Bash)?

**A:** `rbash` is too strict for AI researchers. It blocks:
- Sourcing files
- Changing environment variables
- Redirection (`>`, `>>`)
- Complex piping

This breaks Python Virtual Environments, VS Code Remote SSH, and many Slurm scripts.

**Our approach:** Use "Soft Locking" instead:
- Environment spoofing (`HOME` redirection)
- CD function override
- Path-based access control

### Q: Can a student break out?

**A:** A sufficiently advanced Linux user can technically:
- Unset the `cd` function
- Inspect files in `/home/prof` using absolute paths (e.g., `cat /home/prof/somefile`)

**Mitigation:** This is "Cooperative Multi-Tenancy" for a lab class, **not a high-security prison**. The current setup:
- Prevents accidental damage
- Creates a clean, isolated workspace
- Simplifies management

For true isolation, you need Docker/Singularity or separate Linux users.

### Q: How do Slurm jobs work?

**A:** When a student runs `sbatch script.sh`:

1. The system sees the user as `prof`
2. However, since `HOME` is spoofed in the submission script context, output files appear in the student's folder
3. The student's environment variables (`TRANSFORMERS_CACHE`, etc.) are inherited by the job

**Admin Note:** If checking `squeue` from the admin side, all jobs will be owned by `prof`. Students should use the `squeue` command provided in their environment to see their jobs.

---

## 7. Summary

| Component | Role | Key File |
|-----------|------|----------|
| **Provisioning** | Create student workspaces, symlink tools | `create_students.sh` |
| **Enforcement** | Set environment variables, spoofed HOME | `gatekeeper.sh` |
| **Access Control** | SSH forced command, prevent escape | `~/.ssh/authorized_keys` |
| **Navigation Lock** | Override `cd` to prevent access outside workspace | `.bash_profile` |
| **Dependency Management** | Install pip locally for each student | `get-pip.py` + `pip.conf` |

This design balances **usability, isolation, and maintainability** for a collaborative research environment.

## 8. TODOs and Future Improvements
- [ ] Add reset functionality to restore student environments to a clean state.
- [ ] Add cleanup scripts to remove inactive student accounts.
- [ ] Set resource limits (CPU, GPU, RAM) per student.
- [ ] Implement logging of student activities for audit purposes.