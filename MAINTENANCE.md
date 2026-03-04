# bi0s Pentest Blog — Maintenance Guide

> **Stack:** Jekyll + [Chirpy theme](https://github.com/cotes2020/jekyll-theme-chirpy) (v7.2)
> **Live URL:** <https://pentest.bi0s.in/blog>
> **Repo:** `pentest-bi0s/blog`

---

## Table of Contents

1. [Repository Layout](#repository-layout)
2. [Prerequisites](#prerequisites)
3. [Local Development](#local-development)
4. [Adding a New Blog Post](#adding-a-new-blog-post)
5. [Author Management](#author-management)
6. [Adding Images](#adding-images)
7. [Editing Navigation Tabs](#editing-navigation-tabs)
8. [Configuration Reference](#configuration-reference)
9. [Deployment](#deployment)
10. [Troubleshooting](#troubleshooting)

---

## Repository Layout

```
blog/                              ← Single repo (source + deployment)
├── _config.yml                    ← Site-wide configuration
├── Gemfile                        ← Ruby gem dependencies
├── index.html                     ← Homepage (layout: home)
├── .github/
│   └── workflows/
│       └── pages-deploy.yml       ← GitHub Actions CI/CD workflow
├── _data/
│   └── authors.yml                ← Author registry (REQUIRED)
├── _posts/                        ← Blog posts (Markdown)
├── _tabs/                         ← Navigation tabs (About, Archives, …)
├── assets/
│   └── img/
│       ├── avatar.png             ← Site avatar / logo
│       └── posts/                 ← Post-specific images
└── .gitignore
```

**How it works:** You write posts and config in this repo. When you push to
`main`, a GitHub Actions workflow automatically builds the Jekyll site and
deploys it to GitHub Pages. No separate deployment repo needed.

---

## Prerequisites

| Tool    | Version | Install                                     |
| ------- | ------- | ------------------------------------------- |
| Ruby    | ≥ 3.0   | `sudo apt install ruby-full` or use `rbenv` |
| Bundler | latest  | `gem install bundler`                       |
| Git     | any     | `sudo apt install git`                      |

After cloning, install gems:

```bash
cd blog/
bundle install
```

> If `ffi` fails to compile, install build dependencies:
>
> ```bash
> sudo apt install build-essential libffi-dev
> ```

---

## Local Development

```bash
cd blog/

# Serve with live-reload (default: http://127.0.0.1:4000)
bundle exec jekyll serve --livereload

# Build only (output goes to _site/)
bundle exec jekyll build
```

Press `Ctrl+C` to stop the server.

---

## Adding a New Blog Post

### 1. Create the file

Posts live in `_posts/` and **must** follow this naming convention:

```
YYYY-MM-DD-slug-title.md
```

Example: `_posts/2025-08-15-sql-injection-basics.md`

### 2. Add front matter

Every post **must** start with YAML front matter between `---` fences:

```yaml
---
layout: post
title: "SQL Injection Basics"
date: 2025-08-15 10:00:00 +0530
description: "A beginner's guide to SQL injection attacks and defenses"
categories: [Web Security]
tags: [sql-injection, owasp, web]
author: Anirudh Ajithkumar # Must match a key in _data/authors.yml
toc: true
---
```

#### Front matter fields explained

| Field         | Required | Notes                                                |
| ------------- | -------- | ---------------------------------------------------- |
| `layout`      | ✅       | Always `post`                                        |
| `title`       | ✅       | Post title (in quotes if it has special chars)       |
| `date`        | ✅       | `YYYY-MM-DD HH:MM:SS +OFFSET`                        |
| `description` | ✅       | Short summary shown in previews & SEO                |
| `categories`  | ✅       | Array, e.g. `[Web Security, Writeups]`               |
| `tags`        | ✅       | Array of lowercase tags                              |
| `author`      | ✅       | **Must match a key in `_data/authors.yml`**          |
| `toc`         | ❌       | `true` to show table of contents (default in config) |
| `image`       | ❌       | Path to a banner image for the post                  |
| `pin`         | ❌       | `true` to pin post to the top of the homepage        |
| `math`        | ❌       | `true` to enable MathJax                             |
| `mermaid`     | ❌       | `true` to enable Mermaid diagrams                    |

### 3. Write content in Markdown

After the front matter, write standard Markdown. Chirpy supports:

- **Code blocks** with syntax highlighting (use triple backticks + language)
- **Images** — `![alt text](/assets/img/posts/my-image.png)`
- **Callout/prompts** — `> {: .prompt-tip }`, `.prompt-info`, `.prompt-warning`, `.prompt-danger`
- **Footnotes**, **tables**, **task lists**, etc.

### 4. Preview locally

```bash
bundle exec jekyll serve --livereload
```

Open <http://127.0.0.1:4000> and verify your post appears.

---

## Author Management

Chirpy maps the `author` field in post front matter to entries in
`_data/authors.yml`. **If the author key doesn't exist in this file, the author
name won't render on the post.**

### Current authors file: `_data/authors.yml`

```yaml
Admin:
  name: Admin
  url: https://github.com/pentest-bi0s

Anirudh Ajithkumar:
  name: Anirudh Ajithkumar
  url: https://github.com/pentest-bi0s

s4bot3ur:
  name: s4bot3ur
  url: https://x.com/s4bot3ur

# ... more authors
```

### Adding a new author

1. Open `_data/authors.yml`.
2. Add a new entry:

   ```yaml
   NewAuthorName:
     name: New Author Name
     url: https://github.com/newauthor
   ```

3. In your post front matter, use `author: NewAuthorName` (must match exactly,
   **case-sensitive**).

### Multiple authors on one post

Chirpy supports multiple authors:

```yaml
authors: [s4bot3ur, Anirudh Ajithkumar]
```

Both must exist in `_data/authors.yml`.

---

## Adding Images

### Post images

1. Place images in `assets/img/posts/`:

   ```
   assets/img/posts/my-post-name/
   ├── screenshot1.png
   └── diagram.svg
   ```

2. Reference in your post:

   ```markdown
   ![Screenshot](/assets/img/posts/my-post-name/screenshot1.png)
   ```

### Post banner image

Add to front matter:

```yaml
image:
  path: /assets/img/posts/my-post-name/banner.png
  alt: "Description of the banner"
```

### Site avatar

Replace `assets/img/avatar.png` with your logo (square, ≥ 200×200 px).

---

## Editing Navigation Tabs

Tabs are in `_tabs/`. Each is a Markdown file with special front matter:

| File                  | Tab        | Order |
| --------------------- | ---------- | ----- |
| `_tabs/about.md`      | About      | 4     |
| `_tabs/archives.md`   | Archives   | 1     |
| `_tabs/categories.md` | Categories | 2     |
| `_tabs/tags.md`       | Tags       | 3     |

The `order` field controls left-to-right position. Edit the Markdown body to
change content. **Do not change the `layout: page` line.**

---

## Configuration Reference

Key settings in `_config.yml`:

| Setting       | Current Value           | Description                                      |
| ------------- | ----------------------- | ------------------------------------------------ |
| `title`       | bi0s Pentest Blog       | Site title                                       |
| `tagline`     | Sharing insights…       | Subtitle under title                             |
| `description` | The official blog…      | SEO meta description                             |
| `url`         | https://pentest.bi0s.in | Production domain                                |
| `baseurl`     | /blog                   | Path prefix (repo name, served under the domain) |
| `avatar`      | /assets/img/avatar.png  | Path to site avatar                              |
| `timezone`    | Asia/Kolkata            | Timezone for post dates                          |
| `theme_mode`  | (empty)                 | `light`, `dark`, or empty for auto               |
| `paginate`    | 10                      | Posts per page on homepage                       |
| `toc`         | true                    | Show table of contents on posts                  |

### Social links

```yaml
social:
  name: bi0s Pentest
  email: teambi0spentest@gmail.com
  links:
    - https://github.com/pentest-bi0s
    - https://www.instagram.com/bi0s.pentest
```

Add Twitter, LinkedIn, etc. by appending URLs to the `links` list.

---

## Deployment

Deployment is **fully automated** via GitHub Actions.

### How it works

1. You push to the `main` branch of `pentest-bi0s/blog`
2. GitHub Actions runs `.github/workflows/pages-deploy.yml`
3. It installs Ruby, runs `bundle exec jekyll build`, and deploys to GitHub Pages
4. The site goes live at `https://pentest.bi0s.in/blog` within a few minutes

### To deploy

```bash
git add .
git commit -m "Add new post: My Post Title"
git push origin main
```

That's it. The workflow handles the rest.

### Manual trigger

You can also trigger a deploy without pushing code:

1. Go to the repo on GitHub → **Actions** tab
2. Select **"Build and Deploy"** workflow
3. Click **"Run workflow"**

### First-time GitHub Pages setup

If Pages isn't enabled yet on the `blog` repo:

1. Go to **GitHub → pentest-bi0s/blog → Settings → Pages**
2. Under **Source**, select **"GitHub Actions"** (not "Deploy from a branch")
3. The custom domain `pentest.bi0s.in` should already be configured on the org's `.github.io` repo — the blog will be served at `/blog` path automatically

### Local preview with correct baseurl

```bash
bundle exec jekyll serve --livereload
# Site will be at http://127.0.0.1:4000/blog/
```

---

## Troubleshooting

### Homepage is blank / 404

Make sure `index.html` exists at the repo root with this content:

```html
---
layout: home
# index page
---
```

### Author name not showing on posts

- Check that the `author` value in the post front matter **exactly matches**
  (case-sensitive) a key in `_data/authors.yml`.
- Rebuild after editing `_data/authors.yml`.

### `bundle exec jekyll serve` fails

| Error                    | Fix                                                                 |
| ------------------------ | ------------------------------------------------------------------- |
| `Could not find gem`     | Run `bundle install`                                                |
| `ffi` compilation error  | `sudo apt install build-essential libffi-dev` then `bundle install` |
| `Address already in use` | Another process is using port 4000. Kill it or use `--port 4001`    |
| `Liquid syntax error`    | Check your post's front matter for unescaped special characters     |

### Posts not appearing

- Filename must be `YYYY-MM-DD-slug.md` (no future dates unless you use `--future`)
- Front matter must have `layout: post`
- `date` must not be in the future

### Categories/Tags pages are empty

Make sure `jekyll-archives` is in both `Gemfile` and `_config.yml` plugins list,
and the `jekyll-archives` config block is present:

```yaml
jekyll-archives:
  enabled: [categories, tags]
  layouts:
    category: category
    tag: tag
  permalinks:
    tag: /tags/:name/
    category: /categories/:name/
```

### CSS/JS not loading

- Make sure `url` in `_config.yml` matches your actual domain
- For local dev, the URL is overridden automatically by `jekyll serve`
- If deploying, ensure `JEKYLL_ENV=production` is set during build

### Clearing the cache

```bash
bundle exec jekyll clean
bundle exec jekyll serve
```

---

## Quick Reference — New Post Checklist

- [ ] Create `_posts/YYYY-MM-DD-slug.md`
- [ ] Add all required front matter fields
- [ ] Ensure `author` key exists in `_data/authors.yml`
- [ ] Place images in `assets/img/posts/`
- [ ] Preview locally with `bundle exec jekyll serve --livereload`
- [ ] Commit and push to `main` — GitHub Actions deploys automatically

---

_Last updated: March 2026_
