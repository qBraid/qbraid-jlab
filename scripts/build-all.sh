#!/bin/bash
# build-all.sh - Orchestrates builds for qBraid JupyterLab development
#
# Usage: ./scripts/build-all.sh [OPTIONS]
#
# Options:
#   --ext-only      Only rebuild the qbraid-lab extension (fast)
#   --core-only     Only rebuild JupyterLab core
#   --wheel         Build wheel for distribution
#   --clean         Clean all build artifacts first
#   --help          Show this help message
#
# Examples:
#   ./scripts/build-all.sh              # Full rebuild
#   ./scripts/build-all.sh --ext-only   # Quick extension rebuild
#   ./scripts/build-all.sh --wheel      # Build distributable wheel

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

# Parse arguments
EXT_ONLY=false
CORE_ONLY=false
BUILD_WHEEL=false
CLEAN_FIRST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ext-only)
            EXT_ONLY=true
            shift
            ;;
        --core-only)
            CORE_ONLY=true
            shift
            ;;
        --wheel)
            BUILD_WHEEL=true
            shift
            ;;
        --clean)
            CLEAN_FIRST=true
            shift
            ;;
        --help)
            head -20 "$0" | tail -17
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT"

# Function to print step headers
step() {
    echo -e "\n${GREEN}>>> $1${NC}"
}

# Function to measure time
timer_start() {
    TIMER_START=$(date +%s)
}

timer_end() {
    local elapsed=$(($(date +%s) - TIMER_START))
    echo -e "${BLUE}   Completed in ${elapsed}s${NC}"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}qBraid JupyterLab Build${NC}"
echo -e "${BLUE}========================================${NC}"

# Clean if requested
if [ "$CLEAN_FIRST" = true ]; then
    step "Cleaning build artifacts"
    timer_start

    # Clean JupyterLab
    yarn clean 2>/dev/null || true
    rm -rf dev_mode/static 2>/dev/null || true
    rm -rf jupyterlab/static 2>/dev/null || true

    # Clean extension
    cd "$REPO_ROOT/packages/external/qbraid-lab"
    yarn clean 2>/dev/null || true
    rm -rf qbraid_lab/labextension 2>/dev/null || true
    cd "$REPO_ROOT"

    # Clean wheel
    rm -rf dist/*.whl 2>/dev/null || true

    timer_end
fi

# Extension-only build
if [ "$EXT_ONLY" = true ]; then
    step "Building qbraid-lab extension (TypeScript)"
    timer_start
    cd "$REPO_ROOT/packages/external/qbraid-lab"
    yarn build:lib
    timer_end

    step "Building federated extension"
    timer_start
    jupyter labextension build .
    timer_end

    cd "$REPO_ROOT"

    echo -e "\n${GREEN}✓ Extension build complete${NC}"
    echo -e "Restart JupyterLab to see changes"
    exit 0
fi

# Core-only build
if [ "$CORE_ONLY" = true ]; then
    step "Building JupyterLab core"
    timer_start
    yarn build
    timer_end

    echo -e "\n${GREEN}✓ Core build complete${NC}"
    exit 0
fi

# Full build
step "Building qbraid-lab extension (TypeScript)"
timer_start
cd "$REPO_ROOT/packages/external/qbraid-lab"
yarn build:lib
timer_end

step "Building JupyterLab core"
timer_start
cd "$REPO_ROOT"
yarn build
timer_end

step "Building federated extension"
timer_start
cd "$REPO_ROOT/packages/external/qbraid-lab"
jupyter labextension build .
timer_end

cd "$REPO_ROOT"

# Build wheel if requested
if [ "$BUILD_WHEEL" = true ]; then
    step "Preparing wheel assets"
    timer_start

    # Copy dev_mode static to jupyterlab/static
    # This is required because the wheel uses jupyterlab/static
    rm -rf jupyterlab/static
    cp -r dev_mode/static jupyterlab/static
    echo "   Copied dev_mode/static -> jupyterlab/static"

    timer_end

    step "Building wheel"
    timer_start

    # Ensure build tools are available
    pip install -q build hatchling hatch-jupyter-builder

    # Build wheel
    python -m build --wheel --no-isolation

    timer_end

    # Show wheel info
    WHEEL_FILE=$(ls -t dist/*.whl 2>/dev/null | head -1)
    if [ -n "$WHEEL_FILE" ]; then
        WHEEL_SIZE=$(du -h "$WHEEL_FILE" | cut -f1)
        echo -e "\n${GREEN}✓ Wheel built: $WHEEL_FILE ($WHEEL_SIZE)${NC}"
    fi
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$BUILD_WHEEL" = true ]; then
    echo ""
    echo "To test the wheel:"
    echo -e "  ${BLUE}pip install dist/qbraid_lab-*.whl${NC}"
    echo -e "  ${BLUE}jupyter lab${NC}"
else
    echo ""
    echo "To run JupyterLab:"
    echo -e "  ${BLUE}jupyter lab --dev-mode --extensions-in-dev-mode --no-browser${NC}"
fi
