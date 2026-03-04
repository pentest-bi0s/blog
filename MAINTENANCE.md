# bi0s Pentest Blog — Maintenance Guide

> **Stack:** Jekyll + [Chirpy theme](https://github.com/cotes2020/jekyll-theme-chirpy) (v7.2)
> **Live URL:** <https://pentest.bi0s.in>

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
pentest-blog/
├── blog/                          ← Source repo (this repo)
│   ├── _config.yml                ← Site-wide configuration
│   ├── Gemfile                    ← Ruby gem dependencies
│   ├── index.html                 ← Homepage (layout: home)
│   ├── deploy.sh                  ← Build & deploy script
│   ├── _data/
│   │   └── authors.yml            ← Author registry (REQUIRED)
│   ├── _posts/                    ← Blog posts (Markdown)
│   ├── _tabs/                     ← Navigation tabs (About, Archives, …)
│   ├── assets/
│   │   └── img/
│   │       ├── avatar.png         ← Site avatar / logo
│   │       └── posts/             ← Post-specific images
│   └── .gitignore
│
└── pentest-bi0s.github.io/        ← Deployment repo (GitHub Pages)
    ├── CNAME                      ← Custom domain config
    └── (generated static files)
```

**How it works:** You write posts and config in `blog/`. The `deploy.sh` script
runs `jekyll build`, copies the generated `_site/` into
`pentest-bi0s.github.io/`, and prepares a git commit. You then push that repo
to make the site live.

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

| Setting       | Current Value           | Description                               |
| ------------- | ----------------------- | ----------------------------------------- |
| `title`       | bi0s Pentest Blog       | Site title                                |
| `tagline`     | Sharing insights…       | Subtitle under title                      |
| `description` | The official blog…      | SEO meta description                      |
| `url`         | https://pentest.bi0s.in | Production URL                            |
| `baseurl`     | (empty)                 | Path prefix (leave empty for root domain) |
| `avatar`      | /assets/img/avatar.png  | Path to site avatar                       |
| `timezone`    | Asia/Kolkata            | Timezone for post dates                   |
| `theme_mode`  | (empty)                 | `light`, `dark`, or empty for auto        |
| `paginate`    | 10                      | Posts per page on homepage                |
| `toc`         | true                    | Show table of contents on posts           |

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

### Quick deploy

```bash
cd blog/
bash deploy.sh
cd ../pentest-bi0s.github.io/
git push origin main
```

### What `deploy.sh` does

1. Runs `JEKYLL_ENV=production bundle exec jekyll build`
2. Cleans `pentest-bi0s.github.io/` (preserves `.git/` and `CNAME`)
3. Copies `_site/*` into the deployment repo
4. Stages and commits all changes
5. Prints instructions to push

### Manual deployment

```bash
cd blog/
JEKYLL_ENV=production bundle exec jekyll build
cd ../pentest-bi0s.github.io/
# Remove old files (keep .git and CNAME)
find . -mindepth 1 -not -path './.git*' -not -name 'CNAME' -delete
cp -R ../blog/_site/* .
git add .
git commit -m "Update site - $(date)"
git push origin main
```

### Don't forget to also commit the source repo

```bash
cd blog/
git add .
git commit -m "Add new post: SQL Injection Basics"
git push origin main
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
- [ ] Commit source to `blog/` repo
- [ ] Run `bash deploy.sh` and push `pentest-bi0s.github.io/`

---

_Last updated: July 2025_
