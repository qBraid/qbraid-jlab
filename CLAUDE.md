# CLAUDE.md - qBraid JupyterLab Fork

## Overview

Forked JupyterLab with qBraid UI styling and integrated extensions via git submodules.

## Current State (2026-01-28)

**Working branch:** `feature/extension-submodules` (new architecture with submodules)
**JupyterLab version:** 4.6.0-alpha.2 (Rspack bundler)
**Python venv:** `/Users/kanav/qBraid_repositories/python_environments/jlab-source/bin`

## Architecture: Git Submodules

Extensions are now managed as git submodules in `packages/external/`:

```
packages/external/
├── jupyterlab-git/   → https://github.com/jupyterlab/jupyterlab-git.git
└── qbraid-lab/       → https://github.com/qBraid/qbraid-lab-extensions.git
```

**Benefits:**
- Single build artifact (all extensions bundled together)
- Full control over extension source code
- Easier version management and updates
- Simplified pip install for end users

---

## Quick Start

```bash
# Activate environment
export PATH="/Users/kanav/qBraid_repositories/python_environments/jlab-source/bin:$PATH"

# Initialize submodules (first time only)
git submodule update --init --recursive

# Install dependencies
yarn install

# Build submodules
cd packages/external/jupyterlab-git && jlpm install && jlpm build:lib && cd ../../..
cd packages/external/qbraid-lab && yarn install && yarn build:lib && cd ../../..

# Build JupyterLab
cd dev_mode && npm run build && cd ..

# Run
jupyter lab --dev-mode --extensions-in-dev-mode --watch --no-browser
```

---

## Submodule Management

### Update submodules to latest
```bash
cd packages/external/qbraid-lab && git pull origin main && cd ../../..
cd packages/external/jupyterlab-git && git pull origin main && cd ../../..
git add packages/external/qbraid-lab packages/external/jupyterlab-git
git commit -m "chore: update submodules"
```

### After cloning the repo
```bash
git submodule update --init --recursive
```

### Making changes to submodules
1. Make changes in `packages/external/<submodule>/`
2. Rebuild: `yarn build:lib` (in submodule directory)
3. Rebuild dev_mode: `cd dev_mode && npm run build`
4. Commit submodule changes in the submodule repo
5. Update submodule reference in main repo

---

## Extension Configuration

**Configured in `dev_mode/package.json`:**
```json
"dependencies": {
  "@jupyterlab/git": "file:../packages/external/jupyterlab-git",
  "@qbraid/lab": "file:../packages/external/qbraid-lab"
},
"jupyterlab": {
  "extensions": {
    "@jupyterlab/git": "",
    "@qbraid/lab": ""
  }
}
```

**Workspaces in root `package.json`:**
```json
"workspaces": [
  "packages/*",
  "packages/external/*",  // Required for submodules
  ...
]
```

---

## Python Server Extensions

Both extensions have Python server components that must be installed:

```bash
# Install from PyPI (pre-built)
pip install jupyterlab-git

# Install qbraid-lab from submodule
pip install packages/external/qbraid-lab
```

**Verify server extensions:**
```bash
jupyter server extension list
# Should show: jupyterlab_git, qbraid_lab
```

---

## Branch Structure

| Branch | JupyterLab | Bundler | Status |
|--------|------------|---------|--------|
| `feature/extension-submodules` | 4.6.0-alpha2 | Rspack | **Current - submodule architecture** |
| `main` | 4.6.0-alpha2 | Rspack | Previous (file: references) |
| `fix/jlab-4.5.3` | 4.5.3 | Webpack | Stable fallback |

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

### Watch Mode Limitations
- Watch mode doesn't pick up NEW files - needs manual rebuild
- Watch mode compiles on first start (can take 1-2 minutes)
- Changes to package.json require full rebuild

### Rebuilding After Submodule Changes
```bash
# 1. Rebuild submodule
cd packages/external/qbraid-lab && yarn build:lib && cd ../../..

# 2. Rebuild dev_mode
cd dev_mode && npm run build && cd ..

# 3. Restart JupyterLab
pkill -f jupyter && jupyter lab --dev-mode --extensions-in-dev-mode --watch --no-browser
```

---

## Common Issues

| Problem | Solution |
|---------|----------|
| Extension not loading | Check version match, run `yarn install` from root |
| Changes not picked up | Rebuild submodule, then rebuild dev_mode |
| Server extension missing | `pip install <extension>` for Python components |
| Watch mode hung | Kill rspack processes: `pkill -f rspack` |
| 500 Internal Server Error | Rebuild: `cd dev_mode && npm run build` |
| Submodule not initialized | `git submodule update --init --recursive` |
| "resolving fallback" error | Add `packages/external/*` to workspaces in package.json |

---

## CSS Files

| File | Purpose |
|------|---------|
| `packages/theme-dark-extension/style/variables.css` | JupyterLab variable overrides |
| `packages/theme-dark-extension/style/qbraid-tokens.css` | qBraid design tokens |
| `packages/theme-dark-extension/style/qbraid-components.css` | Component-specific overrides |
| `packages/application/style/core.css` | Top panel, branding |

---

## Disabled Extensions

The following extensions are disabled in `dev_mode/package.json`:
- TOC (Table of Contents)
- Debugger
- Property Inspector
- Running Terminals
- Light theme
- Dark high-contrast theme

---

## qbraid-lab Submodule

See `packages/external/qbraid-lab/CLAUDE.md` for:
- Feature architecture (environments, devices, jobs)
- Redux patterns
- Python handlers
- CSS/styling guidelines

---

## jupyterlab-git Submodule

Standard JupyterLab Git extension. No CLAUDE.md - refer to official docs:
- GitHub: https://github.com/jupyterlab/jupyterlab-git
- Provides: Git panel in left sidebar, diff viewer, commit UI

---

## Module Federation Notes

**sharedPackages Config (in extension package.json):**
```json
"sharedPackages": {
  "react": { "bundled": false, "singleton": true },
  "react-dom": { "bundled": false, "singleton": true }
}
```

- `bundled: false` → Use JupyterLab's React (correct for dev mode)
- `bundled: true` → Bundle own React (use for standalone extensions)

**Version Matching:**
Extension `@jupyterlab/*` deps should match JupyterLab version:
- JupyterLab 4.6.0 → extensions use `@jupyterlab/*: ^4.6.0`
