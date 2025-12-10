# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sixteen is a Crystal library and CLI tool for accessing Base-16 theme data following the Tinted Themes specification. It serves both as:
- A library for embedding Base-16 color themes in Crystal applications
- A CLI tool for building theme files, rendering templates, and browsing themes interactively

## Development Commands

### Building
```bash
# Standard development build
shards build

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

### Core Modules
- `src/sixteen.cr`: Main library with Theme struct and theme loading via baked file system
- `src/main.cr`: CLI interface using docopt with interactive theme browser
- `src/color.cr`: Color manipulation (RGB/HSL conversion, contrast calculations)
- `src/template_file.cr`: Mustache template rendering with Crustache

### Theme System
- All Base-16 themes are embedded in the binary using `baked_file_system`
- Themes stored in `base16/` directory, baked into binary at compile time
- Can compile with selective themes using `SIXTEEN_THEMES` environment variable

### CLI Structure
The `sixteen` binary supports:
- `--list`: Show available themes
- `--info <scheme>`: Theme details
- `--build <template> <scheme>`: Generate theme files
- `--render <template> <scheme>`: Render mustache templates
- `--interactive`: Terminal-based theme browser

## Key Dependencies
- `baked_file_system`: Theme embedding (uses ralsina fork)
- `docopt`: CLI argument parsing (uses ralsina fork)
- `crustache`: Template rendering (dev dependency)
- `lime`: Interactive terminal UI (dev dependency)

## Development Notes
- Crystal version requirement: `>= 1.13.0`
- Build flags: `-Dstrict_multi_assign -Dno_number_autocast` enforced
- Pre-commit hooks handle formatting, YAML validation, and commit message standards
- Binary size increases by ~0.6MB due to embedded 300+ themes
- Uses 2-space indentation per `.editorconfig`
