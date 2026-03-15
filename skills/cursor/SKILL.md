---
description: Cursor IDE configuration and integration context
---

# Cursor IDE

Cursor IDE is managed declaratively via `blackmatter-cursor` (home-manager module).

## Config Files

| File | Managed By | Path |
|------|-----------|------|
| settings.json | blackmatter-cursor | ~/Library/Application Support/Cursor/User/settings.json |
| mcp.json | blackmatter-anvil | ~/.cursor/mcp.json |
| cli-config.json | blackmatter-cursor | ~/.cursor/cli-config.json |
| hooks.json | blackmatter-cursor | ~/.cursor/hooks.json |

## Typed Options

Settings are defined via typed Nix options in `cursor-options.nix` (27 options across 12 sections). Edit options in the nix repo's profile, then rebuild.

## MCP Servers

MCP servers are shared via blackmatter-anvil. They are NOT duplicated in the cursor module. Anvil writes `~/.cursor/mcp.json` with resolved wrapper scripts.

## Extensions

Extensions are installed via `cursor --install-extension` on activation. List them in `cursor.extensions`.

## Key Constraint

Cursor is closed-source. The binary comes from nixpkgs `code-cursor` (DMG download with notarization preserved). The module controls config around it.
