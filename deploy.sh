#!/bin/bash

# Script to build Hugo site and deploy to GitHub Pages repository

# Configuration
HUGO_SITE_DIR="/home/d3vn37/topsecret/dev/pentest-blog/blog"
# Change this to your actual GitHub Pages repository path
GITHUB_PAGES_DIR="/home/d3vn37/topsecret/dev/pentest-blog/pentest-bi0s.github.io"

# Print what we're doing
echo "Building Hugo site from $HUGO_SITE_DIR"
echo "Deploying to $GITHUB_PAGES_DIR"

# Navigate to Hugo site directory
cd "$HUGO_SITE_DIR" || { echo "Failed to navigate to Hugo site directory"; exit 1; }

# Build the site with production settings
echo "Building site with Hugo..."
hugo --minify || { echo "Hugo build failed"; exit 1; }

# Check if GitHub Pages directory exists
if [ ! -d "$GITHUB_PAGES_DIR" ]; then
  echo "GitHub Pages directory not found at $GITHUB_PAGES_DIR"
  echo "Please create or clone your GitHub Pages repository first."
  exit 1
fi

# Clean GitHub Pages directory (preserve .git folder and CNAME if exists)
echo "Cleaning GitHub Pages directory..."
find "$GITHUB_PAGES_DIR" -mindepth 1 -not -path "*/.git*" -not -name "CNAME" -delete

# Copy generated files to GitHub Pages directory
echo "Copying generated files to GitHub Pages directory..."
cp -R "$HUGO_SITE_DIR/public/"* "$GITHUB_PAGES_DIR/" || { echo "Failed to copy files"; exit 1; }

# Navigate to GitHub Pages directory
cd "$GITHUB_PAGES_DIR" || { echo "Failed to navigate to GitHub Pages directory"; exit 1; }

# Add all changes to git
echo "Adding changes to git..."
git add .

# Commit changes
echo "Committing changes..."
git commit -m "Update site - $(date)" || { echo "No changes to commit or commit failed"; }

echo ""
echo "Deployment prepared!"
echo ""
echo "Now run the following commands to push the changes:"
echo "  cd $GITHUB_PAGES_DIR"
echo "  git push origin main"
echo ""
echo "Once pushed, your site will be available at https://pentest-bi0s.github.io/"
