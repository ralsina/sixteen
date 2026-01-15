# Sixteen Static Site Generator Design

> **For Claude:** This design document describes a standalone static site generator for showcasing sixteen's base16 themes.

**Goal:** Create a standalone Crystal generator script that produces a static HTML website showcasing sixteen's base16 theme collection with live previews and syntax-highlighted code examples.

**Date:** 2025-01-15

---

## Overview

The static site generator will be a standalone Crystal program (`site_gen.cr`) that:

1. Reads theme data via the sixteen library
2. Generates theme-specific pico.css overrides using mustache templates
3. Generates syntax-highlighted code samples using tartrazine CLI
4. Outputs static HTML files to a `site/` directory

The site will provide two navigation modes:
- **Families view:** Browse themes grouped by family (dark/light variants)
- **Full list view:** Browse all 300+ themes individually

Each theme page will show two examples:
1. A documentation-style page styled with the theme
2. Syntax-highlighted Crystal code using the theme

---

## Architecture

### Output Structure

```
site/
├── index.html              # Landing page (Monokai-styled)
├── families.html           # Theme families browser
├── themes/
│   ├── monokai.html       # Individual theme preview pages
│   ├── dracula.html
│   └── ...
├── assets/
│   ├── pico.min.css       # Original pico.css (v2.x)
│   ├── monokai.css        # Theme-specific CSS overrides
│   ├── dracula.css
│   └── ...
└── code/
    ├── monokai.html       # tartrazine output (syntax highlighted code)
    ├── dracula.html
    └── ...
```

### Components

**Generator Script (`site_gen.cr`):**
- Standalone Crystal program
- Uses sixteen as a library (`require "sixteen"`)
- Uses crustache for mustache templates
- Invokes tartrazine CLI via `Process.run`

**Templates:**
- `theme_css.mustache` - Generates pico.css theme overrides
- `theme_page.mustache` - Individual theme page HTML
- `index.mustache` - Landing page HTML
- `families.mustache` - Families browser HTML

**Sample Code:**
- `site_gen_assets/sample.cr` - Crystal code snippet for syntax highlighting
- Source: Extracted from `src/sixteen.cr` (the Theme struct)

---

## Page Specifications

### Index Page (`index.html`)

**Purpose:** Landing page with short blurb and theme browser

**Styling:** Fixed Monokai theme (no theme switcher)

**Content:**
```html
<header>
  <h1>Sixteen</h1>
  <p>Base16 Theme Library for Crystal</p>
</header>

<section class="intro">
  <p>Brief description of sixteen...</p>
</section>

<nav class="main-nav">
  <a href="families.html">Browse by Families</a>
  <a href="themes/">Browse All Themes</a>
</nav>

<section class="featured">
  <h2>Featured Themes</h2>
  <!-- Cards for 6-8 popular themes -->
</section>
```

### Families Page (`families.html`)

**Purpose:** Browse themes grouped by family

**Content:**
```html
<header>Same as index</header>

<main>
  <h1>Theme Families</h1>
  <div class="families-list">
    <!-- For each family from Sixteen.theme_families: -->
    <div class="family-card">
      <h3>{{family_name}}</h3>
      <div class="variants">
        <a href="themes/{{dark_theme}}.html">Dark</a>
        <a href="themes/{{light_theme}}.html">Light</a>
      </div>
      <div class="color-preview">
        <!-- Color swatches from base00-base07 -->
      </div>
    </div>
  </div>
</main>
```

### Individual Theme Page (`themes/<slug>.html`)

**Purpose:** Full preview of a single theme

**Content:**
```html
<head>
  <link rel="stylesheet" href="../assets/pico.min.css">
  <link rel="stylesheet" href="../assets/{{theme_slug}}.css">
</head>

<body>
  <header>
    <h1>{{theme_name}}</h1>
    <p>by {{theme_author}} ({{variant}})</p>
  </header>

  <main>
    <section id="demo">
      <h2>Styled Page Example</h2>
      <!-- Documentation-style demo with:
           - Headings (h1-h6)
           - Paragraphs
           - Code blocks (inline and block)
           - Lists (ordered/unordered)
           - Tables
           - Form elements (inputs, buttons)
           - Cards/boxes
           - Blockquotes
      -->
    </section>

    <section id="code">
      <h2>Syntax Highlighted Code</h2>
      <!-- Embed ../code/{{theme_slug}}.html -->
    </section>
  </main>

  <footer>
    <a href="../index.html">Back to Home</a>
  </footer>
</body>
```

---

## CSS Generation Strategy

### Theme CSS Override Template

The generator uses a simplified version of nicolino's `base16.tmpl` for single-variant themes.

**`theme_css.mustache`:**
```css
/* Theme: {{scheme-name}} by {{scheme-author}} */

:root {
  /* Pico CSS color variables */
  --pico-background-color: #{{base00-hex}};
  --pico-color: #{{base05-hex}};
  --pico-text-selection-color: #{{base02-hex}};
  --pico-primary: #{{base0D-hex}};
  --pico-primary-underline: var(--pico-primary);
  --pico-primary-background: #{{base02-hex}};
  --pico-primary-hover: #{{base09-hex}};
  --pico-primary-hover-underline: var(--pico-primary-hover);
  --pico-muted-color: #{{base03-hex}};
  --pico-card-background-color: #{{base01-hex}};
  --pico-card-border-color: #{{base02-hex}};
  --pico-border-color: #{{base02-hex}};
  --pico-code-color: #{{base0A-hex}};

  /* Base16 palette colors for custom styles */
  --b16-base00: #{{base00-hex}};
  --b16-base01: #{{base01-hex}};
  --b16-base02: #{{base02-hex}};
  --b16-base03: #{{base03-hex}};
  --b16-base04: #{{base04-hex}};
  --b16-base05: #{{base05-hex}};
  --b16-base06: #{{base06-hex}};
  --b16-base07: #{{base07-hex}};
  --b16-base08: #{{base08-hex}};
  --b16-base09: #{{base09-hex}};
  --b16-base0A: #{{base0A-hex}};
  --b16-base0B: #{{base0B-hex}};
  --b16-base0C: #{{base0C-hex}};
  --b16-base0D: #{{base0D-hex}};
  --b16-base0E: #{{base0E-hex}};
  --b16-base0F: #{{base0F-hex}};
}
```

**Generation Process:**
1. Load theme: `Sixteen.theme(name)`
2. Get context: `theme.context("_")` (underscore separator for mustache-friendly keys)
3. Render template using crustasse
4. Output to `assets/<theme-slug>.css`

### tartrazine Integration

tartrazine has built-in base16 themes that match sixteen's theme naming.

**Command:**
```bash
tartrazine site_gen_assets/sample.cr -f html -t <theme-name> \
  -o site/code/<theme-slug>.html --standalone
```

The `--standalone` flag includes all necessary CSS inline, so we can directly embed the output.

**Theme Name Mapping:**
- sixteen theme slugs map directly to tartrazine theme names
- Example: `monokai` → tartrazine `monokai` theme

---

## Generator Implementation

### Main Flow

```crystal
require "sixteen"
require "crustache"
require "file_utils"

# Configuration
OUTPUT_DIR = "site"
ASSETS_DIR = "#{OUTPUT_DIR}/assets"
THEMES_DIR = "#{OUTPUT_DIR}/themes"
CODE_DIR = "#{OUTPUT_DIR}/code"

def main
  # 1. Create output directories
  [OUTPUT_DIR, ASSETS_DIR, THEMES_DIR, CODE_DIR].each { |dir| FileUtils.mkdir_p(dir) }

  # 2. Copy pico.css to assets/
  download_pico_css

  # 3. Extract sample code from sixteen's source
  extract_sample_code

  # 4. Get all themes
  themes = Sixteen.available_themes

  # 5. Generate CSS and code for each theme
  themes.each do |theme_name|
    theme = Sixteen.theme(theme_name)
    generate_theme_css(theme)
    generate_syntax_code(theme)
  end

  # 6. Generate pages
  generate_index(themes)
  generate_families
  generate_theme_pages(themes)
end
```

### Sample Code Extraction

**Source:** `src/sixteen.cr` lines 42-163 (the `Theme` struct)

The Theme struct is ideal because it showcases:
- Struct definition
- Properties
- YAML::Serializable include
- Methods (slug, context, term_palette, to_s, [] operators, etc.)

**Extract to:** `site_gen_assets/sample.cr`

### Template Context

Each template receives:
- **site:** Site-wide data (title, description)
- **themes:** Array of all themes (name, slug, author)
- **families:** Array of theme families (for families page)
- **theme:** Current theme data (for theme pages)

---

## Dependencies

**Runtime:**
- `sixteen` - Theme data access
- `crustache` - Mustache template rendering
- Crystal stdlib: `file_utils`, `process`

**External:**
- `tartrazine` CLI - Syntax highlighting (installed separately)
- `pico.css` - Downloaded from CDN during generation

---

## Future Enhancements (Out of Scope)

- Configurable default theme for index page
- Theme search/filter functionality
- Dark/light theme switcher on pages
- Multiple language code samples
- Theme comparison view
- JSON output for dynamic sites
