#!/bin/bash

# Study Buddy AI - Local Start Script
# This script helps you run the application locally

set -e  # Exit on any error

echo "🚀 Starting Study Buddy AI locally..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "📝 Creating .env from env.example..."
    if [ -f env.example ]; then
        cp env.example .env
        echo "✅ Created .env file. Please update it with your API keys!"
        echo "⚠️  Please edit .env file and add your GROQ_API_KEY before continuing."
        exit 1
    else
        echo "❌ env.example not found. Please create .env file manually."
        exit 1
    fi
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

# Check if GROQ_API_KEY is set
if [ -z "$GROQ_API_KEY" ] || [ "$GROQ_API_KEY" == "your_groq_api_key_here" ]; then
    echo "❌ GROQ_API_KEY is not set in .env file!"
    echo "Please update .env file with your actual Groq API key."
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python 3.10 or higher."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
REQUIRED_VERSION="3.10"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Python version $PYTHON_VERSION is too old. Please install Python 3.10 or higher."
    exit 1
fi

# Check if virtual environment exists, create if not
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/upgrade dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip setuptools wheel

# Install dependencies with error handling
echo "📦 Installing application dependencies..."
if pip install -e . 2>&1; then
    echo "✅ Dependencies installed successfully!"
else
    echo "⚠️  Installation encountered issues, trying alternative approach..."
    
    # Try installing with upgraded build tools
    pip install --upgrade pip setuptools wheel build
    
    # Try installing requirements directly
    if [ -f requirements.txt ]; then
        echo "📦 Installing from requirements.txt..."
        pip install -r requirements.txt --no-cache-dir || {
            echo "⚠️  Trying with --no-build-isolation flag..."
            pip install -r requirements.txt --no-build-isolation --no-cache-dir
        }
    fi
    
    # Install the package
    pip install -e . --no-deps 2>/dev/null || echo "⚠️  Some dependencies may have failed, but continuing..."
fi

# Create results directory if it doesn't exist
mkdir -p results

# Set Streamlit port (default 8501)
PORT=${STREAMLIT_SERVER_PORT:-8501}
ADDRESS=${STREAMLIT_SERVER_ADDRESS:-0.0.0.0}

echo "✅ All set! Starting Streamlit application..."
echo "🌐 Application will be available at: http://localhost:$PORT"
echo ""

# Run the application
streamlit run application.py --server.port=$PORT --server.address=$ADDRESS --server.headless=true
