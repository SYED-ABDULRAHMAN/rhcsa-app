#!/bin/bash
#
# RHCSA Lab Quick Setup Script
# This script sets up the complete application structure
#

set -e

echo "╔════════════════════════════════════════╗"
echo "║   🎓 RHCSA Lab Setup Script           ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Define base directory
BASE_DIR="/opt/rhcsa-app"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Warning: Running as root. This is OK for setup."
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$BASE_DIR"/{public,lib,questions,validation}

echo "✅ Directories created:"
echo "   - $BASE_DIR/public"
echo "   - $BASE_DIR/lib"
echo "   - $BASE_DIR/questions"
echo "   - $BASE_DIR/validation"
echo ""

# Check if Node.js is installed
echo "🔍 Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "   Please install Node.js first:"
    echo "   RHEL/Rocky/Alma: sudo dnf install -y nodejs npm"
    echo "   Ubuntu/Debian:   sudo apt install -y nodejs npm"
    exit 1
else
    NODE_VERSION=$(node --version)
    echo "✅ Node.js found: $NODE_VERSION"
fi
echo ""

# Create package.json
echo "📦 Creating package.json..."
cat > "$BASE_DIR/package.json" << 'EOF'
{
  "name": "rhcsa-lab",
  "version": "1.0.0",
  "description": "RHCSA Practice Lab with Real Terminal",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "keywords": ["rhel", "linux", "terminal", "education", "rhcsa"],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^5.1.0",
    "node-pty": "^1.0.0",
    "ws": "^8.18.3"
  }
}
EOF
echo "✅ package.json created"
echo ""

# Install dependencies
echo "📥 Installing Node.js dependencies..."
cd "$BASE_DIR"
npm install
echo "✅ Dependencies installed"
echo ""

# Create validation scripts directory with execute permissions
echo "🔐 Setting up validation scripts..."
chmod 755 "$BASE_DIR/validation"
echo "✅ Validation directory permissions set"
echo ""

# Provide file placement instructions
echo "📋 Next Steps:"
echo ""
echo "1. Place your files in the following locations:"
echo "   - server.js           → $BASE_DIR/"
echo "   - index.html          → $BASE_DIR/public/"
echo "   - questionLoader.js   → $BASE_DIR/lib/"
echo "   - validationRunner.js → $BASE_DIR/lib/"
echo "   - module_index.json   → $BASE_DIR/questions/"
echo "   - module1_users.json  → $BASE_DIR/questions/"
echo "   - validate_q*.sh      → $BASE_DIR/validation/"
echo ""
echo "2. Make validation scripts executable:"
echo "   chmod +x $BASE_DIR/validation/*.sh"
echo ""
echo "3. Start the server:"
echo "   cd $BASE_DIR"
echo "   sudo node server.js"
echo ""
echo "4. Access the application:"
echo "   http://localhost:3000"
echo ""

# Check if files exist
echo "🔍 Checking for required files..."
MISSING_FILES=0

if [ ! -f "$BASE_DIR/server.js" ]; then
    echo "   ⚠️  Missing: server.js"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

if [ ! -f "$BASE_DIR/public/index.html" ]; then
    echo "   ⚠️  Missing: public/index.html"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

if [ ! -f "$BASE_DIR/lib/questionLoader.js" ]; then
    echo "   ⚠️  Missing: lib/questionLoader.js"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

if [ ! -f "$BASE_DIR/lib/validationRunner.js" ]; then
    echo "   ⚠️  Missing: lib/validationRunner.js"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

if [ ! -f "$BASE_DIR/questions/module_index.json" ]; then
    echo "   ⚠️  Missing: questions/module_index.json"
    MISSING_FILES=$((MISSING_FILES + 1))
fi

if [ $MISSING_FILES -eq 0 ]; then
    echo "   ✅ All required files found!"
    echo ""
    echo "🚀 Ready to start! Run:"
    echo "   cd $BASE_DIR"
    echo "   sudo node server.js"
else
    echo ""
    echo "⚠️  $MISSING_FILES file(s) missing. Please add them before starting."
fi

echo ""
echo "════════════════════════════════════════"
echo "Setup complete! Happy learning! 🎓"
echo "════════════════════════════════════════"
