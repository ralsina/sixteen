# Static Site Generator Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a standalone Crystal generator script that produces a static HTML website showcasing sixteen's base16 themes with live previews.

**Architecture:** A standalone Crystal program (`site_gen.cr`) that reads theme data via the sixteen library, generates theme-specific CSS using mustache templates, creates syntax-highlighted code samples via tartrazine CLI, and outputs static HTML files.

**Tech Stack:** Crystal, sixteen library, crustache (mustache), tartrazine CLI, pico.css

---

## Task 1: Create Project Structure and Dependencies

**Files:**
- Create: `site_gen.cr`
- Create: `site_gen_assets/` directory
- Create: `site_gen_assets/theme_css.mustache`
- Modify: `shard.yml` (add crustache dependency)

**Step 1: Add crustache dependency to shard.yml**

```yaml
dependencies:
  baked_file_system:
    github: ralsina/baked_file_system
    branch: master

development_dependencies:
  crustache:
    github: MakeNowJust/crustache
  docopt:
    github: ralsina/docopt.cr
  lime:
    github: ralsina/lime
```

**Step 2: Install dependencies**

Run: `shards install`
Expected: `crustache` is installed successfully

**Step 3: Create site_gen_assets directory**

Run: `mkdir -p site_gen_assets`
Expected: Directory is created

**Step 4: Create initial site_gen.cr with basic structure**

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
  puts "Sixteen Static Site Generator"
  puts "============================="
  puts "Generating site..."
end

main
```

**Step 5: Run it to verify it works**

Run: `crystal run site_gen.cr`
Expected: Output shows "Sixteen Static Site Generator"

**Step 6: Commit**

```bash
git add site_gen.cr site_gen_assets shard.yml
git commit -m "feat: add initial site generator structure"
```

---

## Task 2: Create Theme CSS Mustache Template

**Files:**
- Create: `site_gen_assets/theme_css.mustache`

**Step 1: Create the CSS template**

Create `site_gen_assets/theme_css.mustache`:

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
  --pico-ins-color: #{{base0B-hex}};
  --pico-del-color: #{{base08-hex}};

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

**Step 2: Commit**

```bash
git add site_gen_assets/theme_css.mustache
git commit -m "feat: add theme CSS mustache template"
```

---

## Task 3: Implement Directory Creation and pico.css Download

**Files:**
- Modify: `site_gen.cr`

**Step 1: Add directory creation function to site_gen.cr**

Replace the `main` function in `site_gen.cr` with:

```crystal
def main
  puts "Sixteen Static Site Generator"
  puts "============================="
  puts "Creating output directories..."

  # Create output directories
  [OUTPUT_DIR, ASSETS_DIR, THEMES_DIR, CODE_DIR].each do |dir|
    FileUtils.mkdir_p(dir)
    puts "  Created: #{dir}"
  end

  puts "Done!"
end
```

**Step 2: Run to verify directories are created**

Run: `crystal run site_gen.cr && ls -la site/`
Expected: Output shows `assets/`, `themes/`, `code/` directories

**Step 3: Add pico.css download function**

Add before the `main` function:

```crystal
def download_pico_css
  target = "#{ASSETS_DIR}/pico.min.css"
  url = "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"

  unless File.exists?(target)
    puts "Downloading pico.css..."
    Process.run("curl", ["-sL", "-o", target, url])
    puts "  Downloaded to: #{target}"
  else
    puts "  pico.css already exists, skipping download"
  end
end
```

**Step 4: Call download_pico_css from main**

Add this line at the end of the `main` function:

```crystal
  download_pico_css
```

**Step 5: Run to verify pico.css is downloaded**

Run: `crystal run site_gen.cr && ls -la site/assets/`
Expected: `pico.min.css` exists in `site/assets/`

**Step 6: Commit**

```bash
git add site_gen.cr
git commit -m "feat: add directory creation and pico.css download"
```

---

## Task 4: Implement Theme CSS Generation

**Files:**
- Modify: `site_gen.cr`

**Step 1: Add theme CSS generation function**

Add this function before `main`:

```crystal
def generate_theme_css(theme : Sixteen::Theme)
  template = File.read("site_gen_assets/theme_css.mustache")
  context = theme.context("_")  # underscore separator for mustache-friendly keys

  rendered = Crustache.render(template, context)

  output_path = "#{ASSETS_DIR}/#{theme.slug}.css"
  File.write(output_path, rendered)
  puts "  Generated: #{output_path}"
end
```

**Step 2: Add function to generate CSS for all themes**

Add this function before `main`:

```crystal
def generate_all_theme_css
  puts "Generating theme CSS files..."

  themes = Sixteen.available_themes
  puts "  Found #{themes.size} themes"

  themes.each do |theme_name|
    begin
      theme = Sixteen.theme(theme_name)
      generate_theme_css(theme)
    rescue ex
      puts "  Warning: Failed to load theme '#{theme_name}': #{ex.message}"
    end
  end
end
```

**Step 3: Call generate_all_theme_css from main**

Add this line at the end of the `main` function:

```crystal
  generate_all_theme_css
```

**Step 4: Run to verify CSS generation**

Run: `crystal run site_gen.cr && ls site/assets/*.css | head -5`
Expected: Multiple CSS files exist (pico.min.css and theme CSS files)

**Step 5: Verify one CSS file has correct content**

Run: `head -20 site/assets/monokai.css`
Expected: CSS comment with theme name and CSS variables

**Step 6: Commit**

```bash
git add site_gen.cr
git commit -m "feat: add theme CSS generation"
```

---

## Task 5: Extract Sample Code for Syntax Highlighting

**Files:**
- Modify: `site_gen.cr`
- Create: `site_gen_assets/sample.cr`

**Step 1: Extract Theme struct from sixteen source**

Run: `sed -n '42,163p' src/sixteen.cr > site_gen_assets/sample.cr`

**Step 2: Verify sample.cr was created**

Run: `wc -l site_gen_assets/sample.cr`
Expected: ~122 lines

**Step 3: Add function to generate syntax-highlighted code**

Add this function to `site_gen.cr` before `main`:

```crystal
def generate_syntax_code(theme : Sixteen::Theme)
  output_path = "#{CODE_DIR}/#{theme.slug}.html"

  # Use tartrazine to generate syntax-highlighted HTML
  # Note: tartrazine theme names match sixteen theme slugs
  Process.run("tartrazine", [
    "site_gen_assets/sample.cr",
    "-f", "html",
    "-t", theme.slug,
    "-o", output_path,
    "--standalone"
  ])

  puts "  Generated: #{output_path}"
end
```

**Step 4: Add function to generate code for all themes**

Add this function before `main`:

```crystal
def generate_all_syntax_code
  puts "Generating syntax-highlighted code..."

  themes = Sixteen.available_themes

  themes.each do |theme_name|
    begin
      theme = Sixteen.theme(theme_name)
      generate_syntax_code(theme)
    rescue ex
      puts "  Warning: Failed for theme '#{theme_name}': #{ex.message}"
    end
  end
end
```

**Step 5: Call generate_all_syntax_code from main**

Add this line at the end of the `main` function:

```crystal
  generate_all_syntax_code
```

**Step 6: Run to verify code generation (may take a while)**

Run: `crystal run site_gen.cr && ls site/code/*.html | head -5`
Expected: Multiple HTML files in `site/code/`

**Step 7: Verify one HTML file**

Run: `head -30 site/code/monokai.html`
Expected: HTML with inline styles from tartrazine

**Step 8: Commit**

```bash
git add site_gen.cr site_gen_assets/sample.cr
git commit -m "feat: add syntax-highlighted code generation"
```

---

## Task 6: Create HTML Page Templates

**Files:**
- Create: `site_gen_assets/index_page.mustache`
- Create: `site_gen_assets/theme_page.mustache`
- Create: `site_gen_assets/families_page.mustache`

**Step 1: Create index page template**

Create `site_gen_assets/index_page.mustache`:

```html
<!DOCTYPE html>
<html lang="en" data-theme="monokai">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sixteen - Base16 Theme Library</title>
  <link rel="stylesheet" href="assets/pico.min.css">
  <link rel="stylesheet" href="assets/monokai.css">
</head>
<body>
  <main class="container">
    <h1>Sixteen</h1>
    <p>A Base16 Theme Library for Crystal</p>

    <p>Sixteen provides access to 300+ Base16 color themes for your Crystal applications.
    Browse themes by family or explore the full collection below.</p>

    <nav>
      <ul>
        <li><a href="families.html" role="button">Browse by Families</a></li>
        <li><a href="themes/" role="button" class="secondary">Browse All Themes</a></li>
      </ul>
    </nav>

    <h2>Featured Themes</h2>
    <div class="grid">
      {{#featured_themes}}
      <article>
        <header>
          <strong>{{name}}</strong>
        </header>
        <p>by {{author}}</p>
        <footer>
          <a href="themes/{{slug}}.html" role="button">View</a>
        </footer>
      </article>
      {{/featured_themes}}
    </div>
  </main>
</body>
</html>
```

**Step 2: Create theme page template**

Create `site_gen_assets/theme_page.mustache`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{name}} - Sixteen Themes</title>
  <link rel="stylesheet" href="../assets/pico.min.css">
  <link rel="stylesheet" href="../assets/{{slug}}.css">
</head>
<body>
  <main class="container">
    <header>
      <a href="../index.html">&larr; Back to Home</a>
      <h1>{{name}}</h1>
      <p>by {{author}} &bull; {{variant}} variant</p>
    </header>

    <section>
      <h2>Styled Page Example</h2>

      <h3>Typography</h3>
      <p>This is a paragraph showing the default text color. Base16 themes typically
      have 16 colors in their palette, from <code>base00</code> (background) to
      <code>base0F</code> (builtin/punctuation).</p>

      <h4>Code Examples</h4>
      <p>Inline code looks like <code>variable = "value"</code> while code blocks
      have their own styling.</p>

      <pre><code>def example_function
  puts "Hello, World!"
  return true
end</code></pre>

      <h4>Lists</h4>
      <ul>
        <li>Unordered list item one</li>
        <li>Unordered list item two</li>
        <li>Unordered list item three</li>
      </ul>

      <ol>
        <li>Ordered list item one</li>
        <li>Ordered list item two</li>
        <li>Ordered list item three</li>
      </ol>

      <h4>Blockquote</h4>
      <blockquote>
        "The best color scheme is the one that helps you work comfortably for long hours."
      </blockquote>

      <h4>Tables</h4>
      <table role="grid">
        <thead>
          <tr>
            <th>Color</th>
            <th>Hex</th>
            <th>Usage</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>base00</td>
            <td>{{base00_hex}}</td>
            <td>Background</td>
          </tr>
          <tr>
            <td>base05</td>
            <td>{{base05_hex}}</td>
            <td>Foreground</td>
          </tr>
          <tr>
            <td>base0D</td>
            <td>{{base0D_hex}}</td>
            <td>Primary/Functions</td>
          </tr>
        </tbody>
      </table>

      <h4>Form Elements</h4>
      <form>
        <label for="name">Name
          <input type="text" id="name" name="name" placeholder="Enter your name">
        </label>

        <label for="email">Email
          <input type="email" id="email" name="email" placeholder="your@email.com">
        </label>

        <fieldset>
          <legend>Preferences</legend>
          <label for="option1">
            <input type="radio" id="option1" name="pref" checked>
            Option 1
          </label>
          <label for="option2">
            <input type="radio" id="option2" name="pref">
            Option 2
          </label>
        </fieldset>

        <button type="submit">Submit</button>
        <button type="button" class="secondary">Cancel</button>
      </form>

      <h4>Cards</h4>
      <div class="grid">
        <article>
          <header>Feature One</header>
          <p>Description of feature one using the theme colors.</p>
        </article>
        <article>
          <header>Feature Two</header>
          <p>Description of feature two with more details.</p>
        </article>
        <article>
          <header>Feature Three</header>
          <p>Third feature card showing card styling.</p>
        </article>
      </div>
    </section>

    <section>
      <h2>Syntax Highlighted Code</h2>
      <p>Example Crystal code (from sixteen's Theme struct):</p>
      {{code_html}}
    </section>

    <footer>
      <hr>
      <a href="../index.html">&larr; Back to Home</a>
    </footer>
  </main>
</body>
</html>
```

**Step 3: Create families page template**

Create `site_gen_assets/families_page.mustache`:

```html
<!DOCTYPE html>
<html lang="en" data-theme="monokai">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Theme Families - Sixteen</title>
  <link rel="stylesheet" href="assets/pico.min.css">
  <link rel="stylesheet" href="assets/monokai.css">
</head>
<body>
  <main class="container">
    <header>
      <a href="index.html">&larr; Back to Home</a>
      <h1>Theme Families</h1>
    </header>

    <div class="grid">
      {{#families}}
      <article>
        <header><strong>{{base_name}}</strong></header>
        <p>
          {{#has_dark}}<a href="themes/{{dark_theme}}.html">Dark</a>{{/has_dark}}
          {{#has_light}}<a href="themes/{{light_theme}}.html">Light</a>{{/has_light}}
        </p>
        <div class="color-preview">
          {{#swatches}}
          <span style="background-color: {{.}}; width: 20px; height: 20px; display: inline-block;"></span>
          {{/swatches}}
        </div>
      </article>
      {{/families}}
    </div>
  </main>
</body>
</html>
```

**Step 4: Commit**

```bash
git add site_gen_assets/*.mustache
git commit -m "feat: add HTML page templates"
```

---

## Task 7: Implement Index Page Generation

**Files:**
- Modify: `site_gen.cr`

**Step 1: Add index page generation function**

Add this function before `main`:

```crystal
def generate_index_page(themes : Array(String))
  puts "Generating index page..."

  # Get featured themes (first 8 alphabetically)
  featured_names = themes.first(8).map do |name|
    theme = Sixteen.theme(name)
    {
      "name"   => theme.name,
      "author" => theme.author,
      "slug"   => theme.slug,
    }
  end

  template = File.read("site_gen_assets/index_page.mustache")
  context = {
    "featured_themes" => featured_names,
  }

  rendered = Crustache.render(template, context)
  File.write("#{OUTPUT_DIR}/index.html", rendered)

  puts "  Generated: #{OUTPUT_DIR}/index.html"
end
```

**Step 2: Call generate_index_page from main**

Modify the end of `main` to include:

```crystal
  # Get themes once for reuse
  themes = Sixteen.available_themes

  generate_index_page(themes)
```

**Step 3: Update generate_all_theme_css to not fetch themes internally**

Modify the function signature to accept themes:

```crystal
def generate_all_theme_css(themes : Array(String))
  puts "Generating theme CSS files..."
  puts "  Found #{themes.size} themes"

  themes.each do |theme_name|
    # ... rest of function
```

And update the call in main:

```crystal
  generate_all_theme_css(themes)
```

**Step 4: Update generate_all_syntax_code similarly**

```crystal
def generate_all_syntax_code(themes : Array(String))
```

And update the call:

```crystal
  generate_all_syntax_code(themes)
```

**Step 5: Run to verify index page generation**

Run: `crystal run site_gen.cr && cat site/index.html | head -30`
Expected: HTML with featured themes

**Step 6: Commit**

```bash
git add site_gen.cr
git commit -m "feat: add index page generation"
```

---

## Task 8: Implement Theme Page Generation

**Files:**
- Modify: `site_gen.cr`

**Step 1: Add theme page generation function**

Add this function before `main`:

```crystal
def generate_theme_page(theme : Sixteen::Theme)
  template = File.read("site_gen_assets/theme_page.mustache")

  # Read the syntax-highlighted code HTML
  code_path = "#{CODE_DIR}/#{theme.slug}.html"
  code_html = File.exists?(code_path) ? File.read(code_path) : "<p>Code not available</p>"

  context = {
    "name"       => theme.name,
    "author"     => theme.author,
    "variant"    => theme.variant,
    "slug"       => theme.slug,
    "base00_hex" => theme["base00"].hex,
    "base05_hex" => theme["base05"].hex,
    "base0D_hex" => theme["base0D"].hex,
    "code_html"  => code_html,
  }

  rendered = Crustache.render(template, context)
  output_path = "#{THEMES_DIR}/#{theme.slug}.html"
  File.write(output_path, rendered)

  puts "  Generated: #{output_path}"
end
```

**Step 2: Add function to generate all theme pages**

Add this function before `main`:

```crystal
def generate_all_theme_pages(themes : Array(String))
  puts "Generating theme pages..."

  themes.each do |theme_name|
    begin
      theme = Sixteen.theme(theme_name)
      generate_theme_page(theme)
    rescue ex
      puts "  Warning: Failed for theme '#{theme_name}': #{ex.message}"
    end
  end
end
```

**Step 3: Call generate_all_theme_pages from main**

Add at the end of `main`:

```crystal
  generate_all_theme_pages(themes)
```

**Step 4: Run to verify theme page generation**

Run: `crystal run site_gen.cr && ls site/themes/*.html | head -5`
Expected: Multiple theme HTML files

**Step 5: Check one theme page**

Run: `cat site/themes/monokai.html | head -40`
Expected: Complete HTML page with theme info

**Step 6: Commit**

```bash
git add site_gen.cr
git commit -m "feat: add theme page generation"
```

---

## Task 9: Implement Families Page Generation

**Files:**
- Modify: `site_gen.cr`

**Step 1: Add families page generation function**

Add this function before `main`:

```crystal
def generate_families_page
  puts "Generating families page..."

  families = Sixteen.theme_families

  families_data = families.map do |family|
    # Get color swatches from first dark theme or any theme
    sample_theme = family.dark_themes.first? || family.light_themes.first? || family.other_variants.first?
    swatches = [] of String

    if sample_theme
      begin
        theme = Sixteen.theme(sample_theme)
        8.times do |i|
          key = "base#{i.to_s(16).rjust(2, '0').upcase}"
          swatches << theme[key].hex if theme.palette.has_key?(key)
        end
      rescue
        # Skip if theme fails to load
      end
    end

    {
      "base_name"   => family.base_name,
      "has_dark"    => !family.dark_themes.empty?,
      "dark_theme"  => family.dark_themes.first?,
      "has_light"   => !family.light_themes.empty?,
      "light_theme" => family.light_themes.first?,
      "swatches"    => swatches,
    }
  end

  template = File.read("site_gen_assets/families_page.mustache")
  context = {"families" => families_data}

  rendered = Crustache.render(template, context)
  File.write("#{OUTPUT_DIR}/families.html", rendered)

  puts "  Generated: #{OUTPUT_DIR}/families.html"
end
```

**Step 2: Call generate_families_page from main**

Add at the end of `main`:

```crystal
  generate_families_page
```

**Step 3: Run to verify families page generation**

Run: `crystal run site_gen.cr && cat site/families.html | head -40`
Expected: HTML with family listings

**Step 4: Commit**

```bash
git add site_gen.cr
git commit -m "feat: add families page generation"
```

---

## Task 10: Add CLI Options and Final Polish

**Files:**
- Modify: `site_gen.cr`
- Create: `site_gen_assets/README.md`

**Step 1: Add docopt CLI interface**

Add require at top of `site_gen.cr`:

```crystal
require "docopt"
```

Add DOCOPT constant after requires:

```crystal
DOCOPT = <<-DOCOPT
Sixteen Static Site Generator

Generate a static HTML website showcasing Base16 themes.

Usage:
  site_gen [--output=DIR] [--themes=THEMES]
  site_gen -h | --help
  site_gen --version

Options:
  -h --help         Show this screen.
  --output=DIR      Output directory [default: site].
  --themes=THEMES   Comma-separated theme list (generates all if omitted)
  --version         Show version.
DOCOPT
```

Replace `main` function with:

```crystal
def main
  options = Docopt.docopt(DOCOPT, version: "Sixteen Site Generator 1.0.0")

  output_dir = options["--output"].as(String)
  $output_dir = output_dir
  $assets_dir = "#{output_dir}/assets"
  $themes_dir = "#{output_dir}/themes"
  $code_dir = "#{output_dir}/code"

  puts "Sixteen Static Site Generator"
  puts "============================="
  puts "Output directory: #{output_dir}"

  # Create output directories
  [$output_dir, $assets_dir, $themes_dir, $code_dir].each do |dir|
    FileUtils.mkdir_p(dir)
  end

  # Download pico.css
  download_pico_css

  # Get themes
  themes = if options["--themes"].as?(String)
             options["--themes"].as(String).split(",")
           else
             Sixteen.available_themes
           end

  puts "Processing #{themes.size} themes..."

  # Generate CSS
  generate_all_theme_css(themes)

  # Generate syntax-highlighted code
  generate_all_syntax_code(themes)

  # Generate pages
  generate_index_page(themes)
  generate_families_page
  generate_all_theme_pages(themes)

  puts "\nDone! Site generated in #{output_dir}/"
end

# Global variables for output paths (needed for docopt)
$output_dir = ""
$assets_dir = ""
$themes_dir = ""
$code_dir = ""

# Update all functions to use global variables
OUTPUT_DIR = $output_dir
ASSETS_DIR = $assets_dir
THEMES_DIR = $themes_dir
CODE_DIR = $code_dir
```

**Step 2: Create README for site_gen_assets**

Create `site_gen_assets/README.md`:

```markdown
# Site Generator Assets

This directory contains templates and sample code for generating the sixteen static website.

## Files

- `theme_css.mustache` - Template for generating theme-specific CSS overrides
- `index_page.mustache` - Template for the landing page
- `theme_page.mustache` - Template for individual theme preview pages
- `families_page.mustache` - Template for the theme families browser
- `sample.cr` - Crystal code snippet for syntax highlighting demos

## Usage

Run the generator from the project root:

```bash
crystal run site_gen.cr
```

To specify a custom output directory:

```bash
crystal run site_gen.cr --output=/path/to/output
```

To generate only specific themes:

```bash
crystal run site_gen.cr --themes=monokai,dracula,nord
```
```

**Step 3: Test full generation**

Run: `rm -rf site && crystal run site_gen.cr`
Expected: Clean generation of entire site

**Step 4: Verify output structure**

Run: `find site -type f | head -20`
Expected: HTML, CSS files in correct locations

**Step 5: Commit**

```bash
git add site_gen.cr site_gen_assets/README.md
git commit -m "feat: add CLI options and polish"
```

---

## Task 11: Build Binary and Test

**Files:**
- Create: `Makefile` entry for site_gen

**Step 1: Add site_gen target to Makefile**

Add to Makefile after the `lint` target:

```makefile
site-gen: site_gen.cr
	shards build site_gen
```

**Step 2: Build the binary**

Run: `make site-gen`
Expected: Binary built at `bin/site_gen`

**Step 3: Test binary works**

Run: `rm -rf site && bin/site_gen && ls site/index.html`
Expected: Site generated successfully

**Step 4: Open in browser (manual verification)**

Run: `xdg-open site/index.html` or `open site/index.html` (macOS)
Expected: Browser opens with themed page

**Step 5: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile target for site generator"
```

---

## Task 12: Run Linter and Final Tests

**Files:** None (final validation)

**Step 1: Run linter on site_gen.cr**

Run: `ameba --fix site_gen.cr`
Expected: No linting errors (or auto-fixed)

**Step 2: Run project tests**

Run: `crystal spec`
Expected: All tests pass

**Step 3: Run project linting**

Run: `make lint`
Expected: No linting errors in src/

**Step 4: Full build test**

Run: `make build`
Expected: Sixteen binary builds successfully

**Step 5: Generate final site**

Run: `rm -rf site && bin/site_gen`
Expected: Clean site generation

**Step 6: Verify site is complete**

Run: `echo "Total files: $(find site -type f | wc -l)" && echo "Theme pages: $(ls site/themes/*.html 2>/dev/null | wc -l)" && echo "CSS files: $(ls site/assets/*.css 2>/dev/null | wc -l)"`
Expected: Hundreds of files generated

**Step 7: Commit if any changes**

Run: `git add -A && git status`
Expected: No uncommitted changes or only intentional ones

---

## Final Notes

### Testing the Generated Site

1. Open `site/index.html` in a browser
2. Verify Monokai styling looks correct
3. Click "Browse by Families" - check families page
4. Click on a family link - verify theme page loads
5. Check styled page example shows proper colors
6. Check syntax-highlighted code displays correctly

### Customization

- **Default theme:** Change `data-theme="monokai"` in templates
- **Featured themes:** Modify selection in `generate_index_page`
- **Sample code:** Replace `site_gen_assets/sample.cr`
- **pico.css version:** Update URL in `download_pico_css`

### Performance Note

Generating syntax-highlighted code for 300+ themes can take several minutes. Consider using `--themes` flag for testing during development.
