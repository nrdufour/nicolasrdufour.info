# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal portfolio website for Nicolas R. Dufour built with Hugo static site generator. It's a single-page site showcasing professional experience and contact information.

## Architecture

- **Static Site Generator**: Hugo (legacy configuration using config.yaml)
- **Single Page Site**: Main layout is `layouts/index.html`
- **Modern Bootstrap**: Uses Bootstrap 5.3.2 with Bootstrap Icons
- **Responsive Design**: Mobile-first design that works across all devices

## File Structure

```
.
├── config.yaml              # Hugo site configuration (legacy YAML format)
├── layouts/
│   └── index.html          # Main homepage template
├── static/
│   ├── favicon.ico         # Site favicon
│   ├── nicolas.png         # Profile image
│   └── stylesheet.css      # Custom CSS styles
└── public/                 # Generated site (gitignored)
```

## Development Environment Setup

This project uses Nix and direnv for reproducible development environment:

```bash
# Allow direnv to load the Nix environment (first time only)
direnv allow

# Hugo will be automatically available after direnv loads
```

## Common Commands

### Development
```bash
# Start Hugo development server with live reload
hugo server -D

# Start server and open in browser
hugo server -D --navigateToChanged
```

### Building
```bash
# Build production site (outputs to public/)
hugo

# Build with minification
hugo --minify
```

### Deployment
The built site in `public/` can be deployed to any static hosting service.

## Configuration

- **Base URL**: `https://www.nicolasrdufour.info/`
- **Config Format**: Uses legacy `config.yaml` (consider migrating to `hugo.toml` or `config.toml` for modern Hugo)
- The site uses Hugo's default content rendering with a custom homepage layout

## Styling

- Bootstrap 5.3.2 (latest) loaded from jsDelivr CDN
- Bootstrap Icons for modern iconography
- Custom CSS in `static/stylesheet.css` with:
  - CSS custom properties for theming
  - Hover effects and transitions
  - Responsive typography
  - Accessibility improvements
