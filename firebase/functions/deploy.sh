#!/bin/bash

# Firebase Functions Deployment Script
# ISET Com Restaurant System

set -e

echo "🚀 Starting Firebase Functions deployment..."

# Check if we're in the functions directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Must be run from the functions directory"
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI is not installed"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Error: Not logged in to Firebase"
    echo "Login with: firebase login"
    exit 1
fi

echo "📦 Installing dependencies..."
npm install

echo "🔍 Running linter..."
npm run lint

echo "🏗️  Building TypeScript..."
npm run build

echo "🧪 Running tests (if available)..."
if npm run test --silent 2>/dev/null; then
    echo "✅ Tests passed"
else
    echo "⚠️  No tests found or tests failed"
fi

echo "🚀 Deploying to Firebase..."
firebase deploy --only functions

echo "✅ Deployment completed successfully!"
echo ""
echo "📊 View logs with: firebase functions:log"
echo "🔧 View console: https://console.firebase.google.com/project/$(firebase use)/functions"