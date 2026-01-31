#!/bin/bash
# setup-dev.sh - Automated development environment setup for qBraid JupyterLab
#
# Usage: ./scripts/setup-dev.sh [VENV_PATH] [PYTHON_PATH]
#   VENV_PATH:   Optional path for virtual environment (default: ./venv)
#   PYTHON_PATH: Optional path to Python 3.10+ executable (auto-detected if not provided)
#
# Examples:
#   ./scripts/setup-dev.sh                           # Use defaults
#   ./scripts/setup-dev.sh ./my-venv                 # Custom venv path
#   ./scripts/setup-dev.sh ./venv /usr/bin/python3.12  # Custom Python
#
# This script automates the setup process documented in CLAUDE.md

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Default venv path
VENV_PATH="${1:-$REPO_ROOT/venv}"
PYTHON_CMD="${2:-}"

# Track if we modified workspaces (for cleanup on error)
WORKSPACES_MODIFIED=false
PACKAGE_JSON="$REPO_ROOT/package.json"

# Cleanup function to restore workspaces on error
cleanup() {
    if [ "$WORKSPACES_MODIFIED" = true ] && [ -f "$PACKAGE_JSON" ]; then
        echo -e "\n${YELLOW}Restoring package.json due to error...${NC}"
        git checkout -- "$PACKAGE_JSON" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}qBraid JupyterLab Development Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print step headers
step() {
    echo -e "\n${GREEN}[$1/12] $2${NC}"
}

# Function to print warnings
warn() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Function to print errors
error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Function to check if Python version is acceptable (3.10+)
check_python_version() {
    local python_path="$1"
    if [ ! -x "$python_path" ] && ! command -v "$python_path" &> /dev/null; then
        return 1
    fi
    local version=$("$python_path" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    if [ "$major" -ge 3 ] && [ "$minor" -ge 10 ]; then
        echo "$version"
        return 0
    fi
    return 1
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Find suitable Python
if [ -n "$PYTHON_CMD" ]; then
    # User specified Python path
    PYTHON_VERSION=$(check_python_version "$PYTHON_CMD") || error "Specified Python ($PYTHON_CMD) is not 3.10+"
else
    # Auto-detect Python 3.10+
    for py in python3.13 python3.12 python3.11 python3.10 python3; do
        # Check common paths
        for path in "/opt/homebrew/bin/$py" "/usr/local/bin/$py" "/usr/bin/$py" "$py"; do
            if PYTHON_VERSION=$(check_python_version "$path" 2>/dev/null); then
                PYTHON_CMD="$path"
                break 2
            fi
        done
    done

    if [ -z "$PYTHON_CMD" ]; then
        error "Python 3.10+ is required but not found. Install it or specify path: ./setup-dev.sh ./venv /path/to/python3.12"
    fi
fi
echo "  ✓ Python $PYTHON_VERSION ($PYTHON_CMD)"

# Check Node.js version
if ! command -v node &> /dev/null; then
    error "Node.js is required but not found"
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    error "Node.js 20+ is required (found v$NODE_VERSION)"
fi
echo "  ✓ Node.js $(node -v)"

# Check yarn
if ! command -v yarn &> /dev/null; then
    error "yarn is required but not found"
fi
echo "  ✓ yarn $(yarn -v)"

# Check we're in the right directory
if [ ! -f "$REPO_ROOT/pyproject.toml" ]; then
    error "Must be run from the qbraid-jlab repository root"
fi
echo "  ✓ Repository root found"

cd "$REPO_ROOT"

# Step 1: Create Python virtual environment
step 1 "Creating Python virtual environment at $VENV_PATH"
if [ -d "$VENV_PATH" ]; then
    warn "Virtual environment already exists at $VENV_PATH"
    read -p "Do you want to recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$VENV_PATH"
        "$PYTHON_CMD" -m venv "$VENV_PATH"
        echo "  ✓ Virtual environment recreated"
    else
        echo "  ✓ Using existing virtual environment"
    fi
else
    "$PYTHON_CMD" -m venv "$VENV_PATH"
    echo "  ✓ Virtual environment created"
fi

# Activate venv
source "$VENV_PATH/bin/activate"
pip install --upgrade pip -q
echo "  ✓ Virtual environment activated and pip upgraded"

# Step 2: Initialize git submodules
step 2 "Initializing git submodules"
if [ -d "$REPO_ROOT/packages/external/qbraid-lab/.git" ] || [ -f "$REPO_ROOT/packages/external/qbraid-lab/.git" ]; then
    echo "  ✓ Submodules already initialized"
else
    git submodule update --init --recursive
    echo "  ✓ Submodules initialized"
fi

# Step 3: Install JavaScript dependencies (root)
step 3 "Installing JavaScript dependencies"

# Check if packages/external/* is in workspaces and temporarily remove it
if grep -q '"packages/external/\*"' "$PACKAGE_JSON"; then
    echo "  Temporarily removing packages/external/* from workspaces (geist conflict)..."
    # Use node to safely modify JSON
    node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('$PACKAGE_JSON', 'utf8'));
pkg.workspaces = pkg.workspaces.filter(w => w !== 'packages/external/*');
fs.writeFileSync('$PACKAGE_JSON', JSON.stringify(pkg, null, 2) + '\n');
console.log('  ✓ Workspaces modified');
"
    WORKSPACES_MODIFIED=true
else
    echo "  packages/external/* already removed from workspaces"
    WORKSPACES_MODIFIED=false
fi

yarn install
echo "  ✓ Root dependencies installed"

# Step 4: Build qbraid-lab extension TypeScript
step 4 "Building qbraid-lab extension"
cd "$REPO_ROOT/packages/external/qbraid-lab"

# Install extension dependencies
yarn install
echo "  ✓ Extension dependencies installed"

# Build TypeScript
yarn build:lib
echo "  ✓ Extension TypeScript built"

cd "$REPO_ROOT"

# Step 5: Build jupyterlab-git extension
step 5 "Building jupyterlab-git extension"
cd "$REPO_ROOT/packages/external/jupyterlab-git"

# Install extension dependencies
yarn install
echo "  ✓ jupyterlab-git dependencies installed"

# Build TypeScript
yarn build
echo "  ✓ jupyterlab-git TypeScript built"

cd "$REPO_ROOT"

# Step 6: Install Python build tools (needed for yarn build)
step 6 "Installing Python build tools"
pip install -q editables hatchling hatch-jupyter-builder
echo "  ✓ Python build tools installed"

# Step 7: Build JupyterLab core
step 7 "Building JupyterLab core (this may take a few minutes)"
yarn build
echo "  ✓ JupyterLab core built"

# Step 8: Install JupyterLab Python package
step 8 "Installing JupyterLab Python package"
# Don't use -q flag so we can see errors
if ! pip install --no-build-isolation -e .; then
    error "Failed to install JupyterLab Python package. Check the output above."
fi

# Verify JupyterLab was installed
if ! "$VENV_PATH/bin/python" -c "import jupyterlab; print(f'JupyterLab {jupyterlab.__version__}')" 2>/dev/null; then
    error "JupyterLab installation verification failed"
fi
echo "  ✓ JupyterLab Python package installed and verified"

# Step 9: Build and install federated extensions
step 9 "Building and installing federated extensions"

# Build qbraid-lab federated extension
cd "$REPO_ROOT/packages/external/qbraid-lab"
"$VENV_PATH/bin/jupyter" labextension build .
echo "  ✓ qbraid-lab federated extension built"

# Install qbraid-lab Python package (server handlers)
# Note: This has the same package name as qbraid-jlab, but we need it for server handlers
# The labextension's jupyter-config will enable the server extension
cd "$REPO_ROOT"

# Build jupyterlab-git federated extension (if not already built)
cd "$REPO_ROOT/packages/external/jupyterlab-git"
pip install -e . -q
echo "  ✓ jupyterlab-git installed"

cd "$REPO_ROOT"

# Step 10: Install additional Python dependencies
step 10 "Installing additional Python dependencies"
pip install -q zstandard "qbraid-core>=0.2.0a9"
echo "  ✓ Additional dependencies installed"

# Step 11: Restore workspaces
step 11 "Restoring package.json"
if [ "$WORKSPACES_MODIFIED" = true ]; then
    git checkout -- "$PACKAGE_JSON"
    WORKSPACES_MODIFIED=false  # Prevent cleanup trap from running
    echo "  ✓ package.json restored"
else
    echo "  ✓ No restoration needed"
fi

# Step 12: Verify installation
step 12 "Verifying installation"
echo ""

# Check JupyterLab version
echo "JupyterLab version:"
"$VENV_PATH/bin/python" -c "import jupyterlab; print(f'  {jupyterlab.__version__}')"
echo ""

echo "Extension list:"
"$VENV_PATH/bin/jupyter" labextension list 2>&1 | head -20

echo ""
echo "Server extensions:"
"$VENV_PATH/bin/jupyter" server extension list 2>&1 | grep -E "(enabled|qbraid)" | head -10

# Check for critical extensions
MISSING_EXTENSIONS=""
if ! "$VENV_PATH/bin/jupyter" labextension list 2>&1 | grep -q "@qbraid/lab"; then
    MISSING_EXTENSIONS="$MISSING_EXTENSIONS @qbraid/lab"
fi

if [ -n "$MISSING_EXTENSIONS" ]; then
    warn "Some extensions may be missing:$MISSING_EXTENSIONS"
    echo "  Try rebuilding with: ./scripts/build-all.sh --ext-only"
else
    echo -e "${GREEN}✓ All extensions verified successfully${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To start developing:"
echo ""
echo "  1. Activate the virtual environment:"
echo -e "     ${BLUE}source $VENV_PATH/bin/activate${NC}"
echo ""
echo "  2. Run JupyterLab in dev mode (REQUIRED for this fork):"
echo -e "     ${BLUE}cd $REPO_ROOT${NC}"
echo -e "     ${BLUE}jupyter lab --dev-mode --extensions-in-dev-mode --no-browser${NC}"
echo ""
echo -e "${YELLOW}Note: This fork must be run with --dev-mode flag.${NC}"
echo -e "${YELLOW}Regular 'jupyter lab' will not work without building static assets.${NC}"
echo ""
echo "For more information, see CLAUDE.md"
