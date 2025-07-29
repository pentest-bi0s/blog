#!/bin/bash

# Script to test Hugo site with production baseURL

# Navigate to the site directory
cd "$(dirname "$0")" || exit 1

# Run Hugo server with production configuration
echo "Starting Hugo server with production baseURL..."
echo "Visit http://localhost:1313/ to preview your site with production URLs"
echo "Press Ctrl+C to stop the server"

hugo server \
  --baseURL="https://pentest-bi0s.github.io/" \
  --appendPort=false \
  --buildDrafts
