# blackmatter-cursor

> **★★★ CSE / Knowable Construction.** This repo operates under **Constructive Substrate Engineering** — canonical specification at [`pleme-io/theory/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md`](https://github.com/pleme-io/theory/blob/main/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md). The Compounding Directive (operational rules: solve once, load-bearing fixes only, idiom-first, models stay current, direction beats velocity) is in the org-level pleme-io/CLAUDE.md ★★★ section. Read both before non-trivial changes.


Declarative Cursor IDE provisioning via home-manager. Manages MCP servers,
editor settings, keybindings, and extension installation — all from Nix.

Cursor is closed-source. The binary comes from `nixpkgs#code-cursor` (DMG download
with notarization signature preserved). This module controls everything around it.

## Fleet doctrine: intelligence over speed

`cursor.ai.model` and `cursor.chat.model` are doctrine-controlled —
they flow from `anvil.doctrine.preferredModel` via
`anvil.translatedSettings.cursor.{aiModel,chatModel}`, applied to the
typed options here via `mkDefault`. Per the operator's
belt-and-suspenders decision, the standalone defaults in
`cursor-options.nix` are *also* pinned to `claude-opus-4-6` so that
blackmatter-cursor used without anvil still aligns with doctrine — the
anvil overlay is a no-op when the defaults match (and load-bearing if
they ever drift).

| Setting | Source | Standalone fallback |
|---------|--------|---------------------|
| `cursor.ai.model` | `anvil.translatedSettings.cursor.aiModel` | `"claude-opus-4-6"` |
| `cursor.chat.model` | `anvil.translatedSettings.cursor.chatModel` | `"claude-opus-4-6"` |

To migrate the fleet to a newer top-tier model, edit
`anvil.doctrine.preferredModel` — every consumer (claude/cursor/opencode/…)
re-derives automatically.

## HM Module Options

```nix
blackmatter.components.cursor = {
  enable = true;

  # MCP servers — same format as Claude Desktop / Claude Code
  mcp.servers = {
    atlassian = {
      type = "stdio";
      command = "/path/to/atlassian-mcp-wrapper";
    };
    github = {
      type = "stdio";
      command = "github-mcp-server";
      args = ["stdio"];
    };
  };

  # Editor settings (VS Code format)
  settings = {
    "editor.fontSize" = 14;
    "editor.fontFamily" = "JetBrains Mono, monospace";
    "editor.tabSize" = 2;
    "editor.formatOnSave" = true;
    "files.autoSave" = "afterDelay";
    "workbench.colorTheme" = "Nord";
  };

  # Keybindings (VS Code format)
  keybindings = [
    { key = "ctrl+shift+t"; command = "workbench.action.terminal.toggleTerminal"; }
  ];

  # Extensions (installed on activation)
  extensions = [
    "vscodevim.vim"
    "esbenp.prettier-vscode"
    "rust-lang.rust-analyzer"
    "jnoortheen.nix-ide"
  ];

  # AI provider
  ai.provider = "anthropic";
  ai.model = "claude-sonnet-4-20250514";
};
```

## What gets provisioned

| File | Content |
|------|---------|
| `~/.cursor/mcp.json` | MCP server definitions |
| `~/Library/Application Support/Cursor/User/settings.json` | Editor settings |
| `~/Library/Application Support/Cursor/User/keybindings.json` | Keyboard shortcuts |
| Extensions directory | Installed via `cursor --install-extension` on activation |

## MCP servers

Cursor uses the **exact same MCP format** as Claude Desktop / Claude Code.
The `mcpServers` key in `~/.cursor/mcp.json` mirrors `~/.claude.json`.
This means every MCP wrapper script built for Claude (Atlassian, Slack,
GitHub, K8s, etc.) works identically in Cursor.

## Sharing MCP servers with Claude Code

Both tools read from different files but use the same format:
- Claude Code: `~/.claude.json` (managed by blackmatter-claude)
- Cursor: `~/.cursor/mcp.json` (managed by this module)

To use the same servers in both, reference the same wrapper scripts.
The blackmatter-claude MCP wrapper scripts (e.g., atlassian-mcp-wrapper,
slack-mcp-wrapper) are Nix store paths that both tools can reference.
