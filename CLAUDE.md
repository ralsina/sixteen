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

# Build with specific themes only (reduces binary size)
SIXTEEN_THEMES=horizon-dark,horizon-light shards build -Dnothemes

# Static build for distribution
make static
```

### Testing
```bash
# Run all tests
crystal spec
# or
make test
```

### Linting
```bash
# Fix linting issues automatically
ameba --fix src spec
# or
make lint
```

### Code Quality
- Pre-commit hooks are configured and will run automatically
- Uses Ameba linter with configuration in `.ameba.yml`
- Follows conventional commits via commitizen
- No need to run tests/linters separately when using pre-commit hooks

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
- Commands: `--list`, `--info`, `--build`, `--render`, `--interactive`
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
- Selective builds: `-Dnothemes` flag + `SIXTEEN_THEMES` env var for specific themes
- Themes are accessed via `DataFiles.get("/theme-name.yaml")` at runtime

**Theme Context Generation**:
The `Theme#context(separator)` method generates template variables:
- Scheme metadata: `scheme-name`, `scheme-author`, `scheme-slug`, `scheme-variant`
- Per-color data (16 colors × multiple formats):
  - Hex formats: `base00-hex`, `base00-hex-bgr`, `base00-hex-r`, etc.
  - RGB formats: `base00-rgb-r`, `base00-rgb-g`, `base00-rgb-b`
  - Decimal formats: `base00-dec-r`, `base00-dec-g`, `base00-dec-b`

**Template Rendering**:
- Templates are folders with `config.yaml` (metadata) + `*.mustache` files
- `Template` class parses `config.yaml` for output configuration
- Renders each `.mustache` file with theme context, writes to configured output path

## Key Dependencies

**Runtime**:
- `baked_file_system` (ralsina fork): Theme embedding
- `colorize`: Terminal color output
- `yaml`: Theme file parsing

**Development**:
- `crustache`: Mustache template rendering
- `docopt` (ralsina fork): CLI argument parsing
- `lime`: Interactive terminal UI

## Development Notes
- Crystal version requirement: `>= 1.13.0`
- Build flags enforced: `-Dstrict_multi_assign -Dno_number_autocast`
- Pre-commit hooks handle formatting, YAML validation, and commit message standards
- Binary size increases by ~0.6MB due to embedded 300+ themes
- Uses 2-space indentation per `.editorconfig`
- Theme slugs are auto-generated from names via Unicode normalization and downcasing
