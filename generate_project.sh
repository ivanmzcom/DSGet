#!/bin/bash

# DSGet Project Generator
# Generates the Xcode project using XcodeGen

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 Verificando XcodeGen..."
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Instalando XcodeGen..."
    brew install xcodegen
fi

echo "🚀 Generando proyecto Xcode..."
xcodegen generate

echo ""
echo "✅ Proyecto generado exitosamente!"
echo ""
echo "Para abrir el proyecto:"
echo "  open DSGet.xcodeproj"
