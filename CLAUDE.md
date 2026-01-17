# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sixteen is a Crystal library and CLI tool for accessing Base-16 theme data following the Tinted Themes specification. It serves both as:
- A library for embedding Base-16 color themes in Crystal applications
- A CLI tool for building theme files, rendering templates, and browsing themes interactively

## Development Commands

### Building
```bash
# Standard development build (always uses strict build flags)
make build
# or
shards build -Dstrict_multi_assign -Dno_number_autocast
# or
hace build

# Build with specific themes only (reduces binary size)
SIXTEEN_THEMES=horizon-dark,horizon-light shards build -Dnothemes

# Static build for distribution
make static
# or
hace static
```

**Important:** Never use `--release` flag for development builds. Only use it for release targets (`make release` or `hace build-release`).

### Testing
```bash
# Run all tests
crystal spec
# or
make test
# or
hace test
```

### Linting
```bash
# Fix linting issues automatically
ameba --fix src spec
# or
make lint
# or
hace lint
```

The lint command runs both `crystal tool format` and `ameba --fix`.

### Code Quality
- Pre-commit hooks are configured and will run automatically
- Uses Ameba linter with configuration in `.ameba.yml`
- Follows conventional commits via commitizen
- Hooks run: trailing-whitespace, end-of-file-fixer, check-yaml, check-added-large-files, check-merge-conflict, shellcheck, markdownlint, checkmake, check-github-workflows, commitizen

### Alternative Build System

The project supports both Make and Hacefile:
- `make build` vs `hace build` - Standard development builds
- `make test` vs `hace test` - Run tests
- `make lint` vs `hace lint` - Format and lint
- `make static` vs `hace static` - Static binaries (AMD64 and ARM64)

Both systems are equivalent; use whichever you prefer.

## Architecture

### Library vs CLI Separation

The codebase is organized into two distinct interfaces sharing common core functionality:

**Library Interface** (`src/sixteen.cr`):
- `Sixteen::Theme` struct - Core theme representation with YAML serialization
- `Sixteen::ThemeFamily` struct - Groups related theme variants (dark/light/other)
- `Sixteen::DataFiles` - BakedFileSystem that embeds 300+ theme YAML files at compile time
- `Sixteen.theme(name)` - Retrieves themes by name or slug
- `Sixteen.template(path)` - Loads Tinted Themes template folders
- Theme resolution with automatic variant fallback (dark ↔ light)

**CLI Interface** (`src/main.cr`):
- Docopt-based command parsing with help system
- Commands: `--list`, `--info`, `--build`, `--render`, `--interactive`, `--families`
- Interactive theme browser using Lime terminal UI library
- Template building following Tinted Themes specification

**Supporting Modules**:
- `src/color.cr` - RGB/HSL color conversion and contrast calculations
- `src/template_file.cr` - Mustache rendering with Crustache, template config parsing

### Theme System Architecture

Themes are YAML files in `base16/` with this structure:
```yaml
system: "base16"
name: "Theme Name"
author: "Author Name"
variant: "dark" | "light"
palette:
  base00: "#RRGGBB"  # background
  base01-base08:     # 8 additional colors
  base0A-base0F:     # accent colors
```

**Theme Embedding**:
- Compile-time: `BakedFileSystem` embeds all themes in binary (~0.6MB increase)
- Uses conditional compilation with `-Dnothemes` flag for selective builds
- When `-Dnothemes` is set, reads `SIXTEEN_THEMES` env var (comma-separated theme names)
- Themes are accessed via `DataFiles.get("/theme-name.yaml")` at runtime
- See lines 14-26 in `src/sixteen.cr` for the bake macros

**Theme Context Generation**:
The `Theme#context(separator)` method generates template variables:
- Scheme metadata: `scheme-name`, `scheme-author`, `scheme-slug`, `scheme-variant`
- Per-color data (16 colors × multiple formats):
  - Hex formats: `base00-hex`, `base00-hex-bgr`, `base00-hex-r`, `base00-hex-g`, `base00-hex-b`
  - RGB formats: `base00-rgb-r`, `base00-rgb-g`, `base00-rgb-b` (0-255)
  - Decimal formats: `base00-dec-r`, `base00-dec-g`, `base00-dec-b` (0.0-1.0)

**Template Rendering**:
- Templates are folders with `config.yaml` (metadata) + `*.mustache` files
- `Template` class parses `config.yaml` for output configuration
- Renders each `.mustache` file with theme context, writes to configured output path

### Color Manipulation System

The `Sixteen::Color` class (`src/color.cr`) provides:

**Color Representation:**
- Internal RGB storage as UInt8 components (0-255 per channel)
- Multiple constructors: from hex string, from YAML scalar, from HSL values

**Color Transformations:**
- `hsl` - Converts RGB to HSL (hue, saturation, luminance)
- `lighter(amount)` / `darker(amount)` - Adjust luminance by ±0.1 (default)
- `invert_for_theme(target)` - Smart inversion for auto-generating theme variants
  - Preserves hue relationships
  - Adjusts luminance and saturation appropriately
  - Used by `Theme#invert_for_theme(:light)` and `Theme#invert_for_theme(:dark)`
  - See lines 124-144 in `src/color.cr`

**Color Analysis:**
- `light?` / `dark?` - Determines if color is light (r+g+b > 384)
- `contrast(other)` - Calculates WCAG contrast ratio between two colors
- `hex` / `hex_bgr` - String representations

### Theme Family System

Themes are grouped into families based on base names:

**Family Detection:**
- `extract_base_name()` removes suffixes like `-dark`, `-light`, `-hard`, `-soft`
- Special case mappings for irregular theme names (catppuccin, rose-pine)
- Families group dark/light/other variants together

**Variant Resolution:**
`Sixteen.theme_with_fallback(name, preferred_variant)` implements smart lookup:
1. Try exact match first
2. Try base-name + preferred variant suffix
3. Try base-name alone
4. Special mappings for known themes
5. Auto-generate using `invert_for_theme` if not found

**Auto-Generation:**
- Only generates variants when family doesn't have both dark and light
- Uses `Color#invert_for_theme` to create appropriate contrast
- Auto-generated themes include `-auto-` in their name suffix

### Static Site Generator

The `gen_site.cr` script generates a static HTML showcase:

**Architecture:**
- Standalone Crystal script using the sixteen library
- Templates in `site_showcase/` directory (`.mustache` files)
- Outputs to `site/` directory
- Uses tartrazine CLI for syntax highlighting

**Key Features:**
- Generates pages for all 300+ themes
- Auto-generates light/dark variants for themes without both
- Family navigation between related themes
- Pico.css-based styling with theme-specific CSS overrides
- Two-pass generation: first detects families with both variants, then generates

**Template Files:**
- `theme.html.mustache` - Main theme page template
- `theme.css.mustache` - CSS generation with theme colors
- `index.html.mustache` - Index page (generated by `site_showcase/generate-index.cr`)

**Usage:**
```bash
./gen_site.cr
```

## Key Dependencies

**Runtime**:
- `baked_file_system` (ralsina fork): Theme embedding via compile-time macros
- `colorize`: Terminal color output
- `yaml`: Theme file parsing

**Development**:
- `crustache`: Mustache template rendering
- `docopt` (ralsina fork): CLI argument parsing
- `lime`: Interactive terminal UI for theme browser
- `tartrazine`: Syntax highlighting (for site generation, CLI tool)

**External Tools**:
- `pre-commit`: Git hooks framework
- `git-cliff`: Changelog generation
- `ameba`: Crystal linter

## Development Notes
- Crystal version requirement: `>= 1.13.0`
- Build flags enforced: `-Dstrict_multi_assign -Dno_number_autocast` (via Makefile/Hacefile)
- Pre-commit hooks handle formatting, YAML validation, and commit message standards
- Binary size increases by ~0.6MB due to embedded 300+ themes
- Uses 2-space indentation per `.editorconfig`
- Theme slugs are auto-generated from names via Unicode normalization and downcasing
- Ameba only checks for TODO/FIXME/BUG admonitions in documentation
- Test coverage is minimal - consider adding tests for new features
