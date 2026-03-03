#!/bin/bash

# Script to build Jekyll Chirpy site and deploy to GitHub Pages repository

# Configuration
JEKYLL_SITE_DIR="/home/d3vn37/topsecret/dev/pentest-blog/blog"
GITHUB_PAGES_DIR="/home/d3vn37/topsecret/dev/pentest-blog/pentest-bi0s.github.io"

# Print what we're doing
echo "Building Jekyll site from $JEKYLL_SITE_DIR"
echo "Deploying to $GITHUB_PAGES_DIR"

# Navigate to Jekyll site directory
cd "$JEKYLL_SITE_DIR" || { echo "Failed to navigate to Jekyll site directory"; exit 1; }

# Build the site with production settings
echo "Building site with Jekyll..."
JEKYLL_ENV=production bundle exec jekyll build || { echo "Jekyll build failed"; exit 1; }

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
cp -R "$JEKYLL_SITE_DIR/_site/"* "$GITHUB_PAGES_DIR/" || { echo "Failed to copy files"; exit 1; }

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
echo "Your site will be live at https://pentest.bi0s.in/ in a few minutes."
