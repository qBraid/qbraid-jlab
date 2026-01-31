# CLAUDE.md - qBraid JupyterLab Fork

## Overview

Forked JupyterLab with qBraid UI styling. The qbraid-lab extension is loaded as a **federated extension** (not bundled).

## Current State (2026-01-31)

**Working branch:** `feature/federated-qbraid-lab`
**JupyterLab version:** 4.6.0-alpha.2 (Rspack bundler)
**Architecture:** qbraid-lab as federated extension (separate from JupyterLab build)

---

## Automated Setup (Recommended)

Use the provided scripts for quick setup:

### Quick Start - Development Environment

```bash
# Clone the repo (if not already done)
git clone https://github.com/qBraid/qbraid-jlab.git
cd qbraid-jlab
git checkout feature/federated-qbraid-lab
git submodule update --init --recursive

# Run automated setup (creates venv at ./venv by default)
./scripts/setup-dev.sh

# Or specify a custom venv path
./scripts/setup-dev.sh /path/to/your/venv

# Or specify both venv path and Python executable
./scripts/setup-dev.sh /path/to/venv /opt/homebrew/bin/python3.12
```

The script will:
1. Auto-detect Python 3.10+ (or use specified path)
2. Create virtual environment
3. Handle the `geist` package workspace conflict automatically
4. Build all TypeScript and extensions
5. Install all Python packages
6. Verify the installation

After setup, activate and run:
```bash
source ./venv/bin/activate
jupyter lab --dev-mode --extensions-in-dev-mode --no-browser
```

### Build Scripts

```bash
# Quick rebuild after extension changes (fastest)
./scripts/build-all.sh --ext-only

# Rebuild JupyterLab core only
./scripts/build-all.sh --core-only

# Full rebuild (extension + core)
./scripts/build-all.sh

# Build distributable wheel
./scripts/build-all.sh --wheel

# Clean and rebuild everything
./scripts/build-all.sh --clean
```

### Building a Distributable Wheel

```bash
# Activate your dev environment
source ./venv/bin/activate

# Build the wheel (handles asset copying automatically)
./scripts/build-all.sh --wheel

# Test in a fresh environment
python3 -m venv /tmp/test-wheel
source /tmp/test-wheel/bin/activate
pip install dist/qbraid_lab-*.whl
jupyter lab
```

---

## Architecture: Federated Extensions

Extensions are git submodules built and installed **separately** as federated extensions:

```
packages/external/
├── qbraid-lab/       → https://github.com/qBraid/qbraid-lab-extensions.git
└── jupyterlab-git/   → https://github.com/jupyterlab/jupyterlab-git.git
```

**Why federated (not bundled)?**
- Rspack ES module timing issues caused `module.default` to be undefined when bundled
- Federated extensions load after JupyterLab core, avoiding timing issues
- Cleaner separation between JupyterLab core and extensions

---

## Manual Setup (Step-by-Step)

### Prerequisites
- Python 3.12
- Node.js 20+
- yarn

### Step 1: Create Python Virtual Environment
```bash
python3.12 -m venv /path/to/your/venv
source /path/to/your/venv/bin/activate
pip install --upgrade pip
```

### Step 2: Clone and Initialize Repository
```bash
git clone https://github.com/qBraid/qbraid-jlab.git
cd qbraid-jlab
git checkout feature/federated-qbraid-lab
git submodule update --init --recursive
```

### Step 3: Install JavaScript Dependencies
```bash
yarn install
```

### Step 4: Build Extension TypeScript (lib only, not extensions yet)
```bash
# Build qbraid-lab
cd packages/external/qbraid-lab
yarn install
yarn build:lib
cd ../../..

# Build jupyterlab-git
cd packages/external/jupyterlab-git
yarn install
yarn build
cd ../../..
```

### Step 5: Temporarily Remove External Packages from Workspaces

**IMPORTANT:** The `geist` package in qbraid-lab causes build conflicts. Temporarily edit `package.json`:

```bash
# In root package.json, remove "packages/external/*" from workspaces array
# Change this:
#   "packages/*",
#   "packages/external/*",
# To this:
#   "packages/*",
```

Then reinstall:
```bash
yarn install
```

### Step 6: Build JupyterLab Core
```bash
# Ensure venv is activated for hatchling
source /path/to/your/venv/bin/activate
yarn build
```

### Step 7: Install JupyterLab Python Package
```bash
pip install editables
pip install --no-build-isolation -e .
```

### Step 8: Build and Install Federated Extensions
```bash
# Install qbraid-lab
cd packages/external/qbraid-lab
jupyter labextension build .
pip install -e .
cd ../../..

# Install jupyterlab-git
cd packages/external/jupyterlab-git
pip install -e .
cd ../../..
```

### Step 9: Install Missing Python Dependencies
```bash
pip install zstandard qbraid-core>=0.2.0a9
```

### Step 10: Restore Workspaces (Optional)
```bash
# Add "packages/external/*" back to workspaces in package.json
```

### Step 11: Verify Extensions
```bash
jupyter labextension list
# Should show:
#   @qbraid/lab v0.1.0 enabled OK
#   @jupyterlab/git v0.51.4 enabled OK
```

### Step 12: Run JupyterLab
```bash
jupyter lab --dev-mode --extensions-in-dev-mode --no-browser
```

---

## Quick Start (After Initial Setup)

```bash
# Activate environment
source /path/to/your/venv/bin/activate

# Run JupyterLab
cd /path/to/qbraid-jlab
jupyter lab --dev-mode --extensions-in-dev-mode --no-browser
```

---

## Rebuilding After qbraid-lab Changes

When you modify qbraid-lab source code:

```bash
# Option 1: Use the build script (recommended)
./scripts/build-all.sh --ext-only
# Then restart JupyterLab

# Option 2: Manual rebuild
cd packages/external/qbraid-lab
yarn build:lib
jupyter labextension build .
cd ../../..
# Restart JupyterLab
```

---

## Building the Wheel (`pip install qbraid-lab`)

**Recommended:** Use the build script:
```bash
./scripts/build-all.sh --wheel
```

**Manual steps** (if needed):

```bash
# 1. Ensure dev environment works first
source /path/to/your/venv/bin/activate
jupyter lab --dev-mode --extensions-in-dev-mode --no-browser
# Verify the UI loads correctly, then stop the server

# 2. Build dev_mode assets (uses local packages with qBraid theme)
yarn build

# 3. Copy dev_mode assets to jupyterlab/static
cp -r dev_mode/static jupyterlab/static

# 4. Build the wheel (skips JS build, uses pre-built assets)
python -m build --wheel --no-isolation

# 5. Test the wheel in a fresh environment
python -m venv /tmp/test-qbraid
source /tmp/test-qbraid/bin/activate
pip install dist/qbraid_lab-*.whl
jupyter lab
```

**IMPORTANT:** The wheel MUST use `dev_mode/static` assets, NOT `jupyterlab/staging` build. The staging build pulls from npm and doesn't include local qBraid theme modifications.

See `ARCHITECTURE.md` for detailed packaging strategy.

---

## Common Issues

| Problem | Solution |
|---------|----------|
| `geist` package error during build | Remove `packages/external/*` from workspaces temporarily |
| `No module named 'editables'` | `pip install editables` |
| `No module named 'zstandard'` | `pip install zstandard` |
| `hatchling: command not found` | Activate Python venv before building |
| `jupyter-labextension not found` | Install jupyterlab first: `pip install --no-build-isolation -e .` |
| Extension not showing | Run `jupyter labextension list` to verify, rebuild if needed |
| Server extension error | `pip install -e packages/external/qbraid-lab` |

---

## Key Files

| File | Purpose |
|------|---------|
| `package.json` | Root workspaces config - may need `packages/external/*` removed during build |
| `dev_mode/package.json` | Dev mode config - qbraid-lab NOT listed here (it's federated) |
| `packages/external/qbraid-lab/` | qbraid-lab extension source |

---

## Development Tips

### Version Indicator
qbraid-lab has a version indicator in the Environments panel header (e.g., `ENVIRONMENTS_V84`).
Update this when making changes to confirm new code is loaded:
- File: `packages/external/qbraid-lab/src/features/environments/components/EnvironmentsSidebar.tsx`

### CSS Version Indicator
JupyterLab theme has a CSS version indicator in the top panel:
- File: `packages/theme-dark-extension/style/qbraid-components.css`
- Look for: `content: 'C9H'` (update letter/number when making CSS changes)

---

## Why This Architecture?

The previous approach tried to bundle qbraid-lab directly into JupyterLab's dev_mode build. This failed due to:

1. **Rspack ES module timing**: When bundled, `module.default` was undefined at load time
2. **geist package conflicts**: The `geist` font package doesn't export properly, breaking the monorepo build

The federated extension approach solves both issues:
- qbraid-lab builds independently with its own webpack config
- Loads after JupyterLab core is fully initialized
- No conflicts with the main build process

---

## Branch History

| Branch | Status | Notes |
|--------|--------|-------|
| `feature/federated-qbraid-lab` | **Current** | qbraid-lab as federated extension |
| `feature/extension-submodules` | Deprecated | Attempted bundled approach (had issues) |
| `main` | Stable | Base JupyterLab without qbraid-lab |

---

## qbraid-lab Submodule

See `packages/external/qbraid-lab/CLAUDE.md` for:
- Feature architecture (environments, devices, jobs)
- Redux patterns
- Python handlers
- CSS/styling guidelines
