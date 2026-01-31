# qBraid Lab Architecture

## Overview

qBraid Lab is a customized JupyterLab distribution that bundles:
- **JupyterLab core** (forked from jupyterlab/jupyterlab)
- **qbraid-lab extension** (environments, devices, jobs panels)
- **jupyterlab-git extension** (git integration)

## Repository Structure

```
qbraid-jlab/                          # Main repo (JupyterLab fork)
├── jupyterlab/                       # Python package (jupyter commands)
├── packages/                         # Core JupyterLab JS packages
├── packages/external/
│   ├── qbraid-lab/                   # Git submodule → qbraid-lab-extensions
│   └── jupyterlab-git/               # Git submodule → jupyterlab/jupyterlab-git
├── dev_mode/                         # Development build output
├── CLAUDE.md                         # AI assistant instructions
└── ARCHITECTURE.md                   # This file
```

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│  qbraid-jlab (JupyterLab fork)                                  │
│  github.com/qBraid/qbraid-jlab                                  │
│                                                                 │
│  ├── jupyterlab/          # Python pkg (provides jupyter cmd)   │
│  ├── packages/            # Core JupyterLab JS packages         │
│  ├── packages/external/                                         │
│  │   ├── qbraid-lab/      # SUBMODULE → qbraid-lab-extensions  │
│  │   └── jupyterlab-git/  # SUBMODULE → jupyterlab-git         │
│  └── dev_mode/            # Dev build output                    │
└─────────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┴──────────────────┐
           ▼                                     ▼
┌──────────────────────────┐        ┌──────────────────────────┐
│  qbraid-lab-extensions   │        │  jupyterlab-git          │
│  github.com/qBraid/...   │        │  github.com/jupyterlab/..│
│                          │        │                          │
│  Federated extension     │        │  Federated extension     │
│  Built separately        │        │  Built separately        │
│  pip install -e .        │        │  pip install -e .        │
└──────────────────────────┘        └──────────────────────────┘
```

## Federated Extensions

Extensions are **not bundled** into the JupyterLab core build. Instead:

1. JupyterLab core is built once (outputs to `dev_mode/static/`)
2. Each extension is built separately with `jupyter labextension build .`
3. Extensions are pip installed and register themselves via entry points
4. At runtime, JupyterLab discovers and loads federated extensions from `share/jupyter/labextensions/`

**Why federated?**
- Rspack ES module timing issues prevented bundling (module.default was undefined)
- Cleaner separation between core and extensions
- Extensions can be updated independently

## Development Setup

### Prerequisites
- Python 3.12
- Node.js 20+
- yarn

### Build Order

```bash
# 1. Clone with submodules
git clone https://github.com/qBraid/qbraid-jlab.git
cd qbraid-jlab
git checkout feature/federated-qbraid-lab
git submodule update --init --recursive

# 2. Install JS dependencies
yarn install

# 3. Build extension TypeScript
cd packages/external/qbraid-lab && yarn install && yarn build:lib && cd ../../..
cd packages/external/jupyterlab-git && yarn install && yarn build && cd ../../..

# 4. Temporarily remove external packages from workspaces (geist conflict)
# Edit package.json: remove "packages/external/*" from workspaces
yarn install

# 5. Build JupyterLab core
source /path/to/venv/bin/activate
yarn build

# 6. Install JupyterLab Python package
pip install editables
pip install --no-build-isolation -e .

# 7. Build and install federated extensions
cd packages/external/qbraid-lab
jupyter labextension build .
pip install -e .
cd ../../..

cd packages/external/jupyterlab-git
pip install -e .
cd ../../..

# 8. Install additional dependencies
pip install zstandard qbraid-core>=0.2.0a9

# 9. Restore workspaces (optional)
# Edit package.json: add "packages/external/*" back to workspaces

# 10. Run
jupyter lab --dev-mode --extensions-in-dev-mode --no-browser
```

## Packaging Strategy

### Goal: `pip install qbraid-lab`

Users should be able to install everything with a single command.

### Approach: Single Package with Pre-built Assets

The wheel includes:
- **JupyterLab core** with qBraid theme (`jupyterlab/` Python package + `jupyterlab/static/` assets)
- **@qbraid/lab** federated extension (from `packages/external/qbraid-lab/qbraid_lab/labextension/`)
- **qbraid_lab** Python handlers (from `packages/external/qbraid-lab/qbraid_lab/`)

```
qbraid-lab wheel contents:
├── jupyterlab/                        # JupyterLab Python package
├── qbraid_lab/                        # qBraid extension handlers
└── qbraid_lab-*.data/data/
    ├── share/jupyter/lab/static/      # Pre-built JupyterLab assets (with qBraid theme)
    ├── share/jupyter/labextensions/@qbraid/lab/  # Federated extension
    └── etc/jupyter/jupyter_server_config.d/      # Server extension config
```

### Building the Wheel

**IMPORTANT:** The wheel must use dev_mode build assets (not staging). The staging build pulls from npm and doesn't include local qBraid theme modifications.

```bash
# 1. Ensure dev environment is set up and working
source /path/to/venv/bin/activate
jupyter lab --dev-mode --extensions-in-dev-mode  # Test first

# 2. Build dev_mode assets (includes local qBraid theme)
yarn build

# 3. Copy dev_mode assets to jupyterlab/static
cp -r dev_mode/static jupyterlab/static

# 4. Build the qbraid-lab extension (if not already built)
cd packages/external/qbraid-lab
yarn build:lib
jupyter labextension build .
cd ../../..

# 5. Build the wheel
python -m build --wheel --no-isolation

# 6. Test the wheel
pip install dist/qbraid_lab-*.whl
jupyter lab
```

### Why dev_mode Assets?

The `jupyterlab/staging` directory is configured to pull packages from npm, which doesn't include local modifications. The `dev_mode` build uses `linkedPackages` to include local packages (like `theme-dark-extension` with qBraid styling).

| Build | Source | Includes Local Packages? |
|-------|--------|-------------------------|
| `dev_mode/static` | `packages/` via linkedPackages | ✅ Yes |
| `jupyterlab/static` (staging) | npm registry | ❌ No |

### pyproject.toml Key Configuration

```toml
[project]
name = "qbraid-lab"
dependencies = [
    # JupyterLab core
    "jupyter-server>=2.4.0,<3",
    "jupyterlab-server>=2.28.0,<3",
    # qBraid extension
    "qbraid-core>=0.2.0a9",
    "zstandard",
]

[tool.hatch.build.targets.wheel.shared-data]
"jupyterlab/static" = "share/jupyter/lab/static"
"packages/external/qbraid-lab/qbraid_lab/labextension" = "share/jupyter/labextensions/@qbraid/lab"
"packages/external/qbraid-lab/jupyter-config/server-config" = "etc/jupyter/jupyter_server_config.d"

[tool.hatch.build.targets.wheel.force-include]
"packages/external/qbraid-lab/qbraid_lab" = "qbraid_lab"

[tool.hatch.build.hooks.jupyter-builder]
skip-if-exists = ["jupyterlab/static/package.json"]  # Use pre-built assets
```

## Key Files

| File | Purpose |
|------|---------|
| `pyproject.toml` | Python package configuration |
| `package.json` | Root JS workspace configuration |
| `dev_mode/package.json` | Dev build configuration |
| `CLAUDE.md` | AI assistant build instructions |
| `ARCHITECTURE.md` | This file |

## Branches

| Branch | Purpose |
|--------|---------|
| `feature/federated-qbraid-lab` | Current development (federated extensions) |
| `main` | Stable base |

## Related Repositories

| Repository | Purpose |
|------------|---------|
| [qBraid/qbraid-jlab](https://github.com/qBraid/qbraid-jlab) | JupyterLab fork (this repo) |
| [qBraid/qbraid-lab-extensions](https://github.com/qBraid/qbraid-lab-extensions) | qbraid-lab extension source |
| [jupyterlab/jupyterlab-git](https://github.com/jupyterlab/jupyterlab-git) | Git extension (external) |
