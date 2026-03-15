# blackmatter-cursor — Declarative Cursor IDE provisioning
#
# Manages:
#   - ~/.cursor/mcp.json (MCP servers — same format as Claude Desktop)
#   - ~/Library/Application Support/Cursor/User/settings.json
#   - ~/Library/Application Support/Cursor/User/keybindings.json
#   - Extension installation via activation script
#
# MCP servers mirror blackmatter-claude's MCP config so both tools
# share the same integrations (Atlassian, Slack, GitHub, K8s, etc.).
{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.blackmatter.components.cursor;
  homeDir = config.home.homeDirectory;
  appSupport = "${homeDir}/Library/Application Support/Cursor";

  # Build the MCP servers JSON
  mcpServersJson = builtins.toJSON { mcpServers = cfg.mcp.servers; };

  # Build settings.json from attrset
  settingsJson = builtins.toJSON cfg.settings;

  # Build keybindings.json from list
  keybindingsJson = builtins.toJSON cfg.keybindings;

  # Extension install script
  extensionInstallScript = let
    cmds = map (ext: ''
      if ! "${cfg.package}/bin/cursor" --list-extensions 2>/dev/null | grep -q "^${ext}$"; then
        "${cfg.package}/bin/cursor" --install-extension "${ext}" 2>/dev/null || true
      fi
    '') cfg.extensions;
  in concatStringsSep "\n" cmds;
in {
  options.blackmatter.components.cursor = {
    enable = mkEnableOption "Cursor IDE declarative configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.code-cursor;
      description = "Cursor IDE package.";
    };

    mcp = {
      servers = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          MCP server definitions. Same format as Claude Desktop / Claude Code mcpServers.
          Written to ~/.cursor/mcp.json.
        '';
        example = {
          github = {
            type = "stdio";
            command = "github-mcp-server";
            args = [ "stdio" ];
          };
        };
      };

      mirrorClaude = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If true, automatically include all MCP servers configured in
          blackmatter.components.claude.mcp.* (Atlassian, Slack, etc.).
          Additional servers in cursor.mcp.servers are merged on top.
        '';
      };
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Cursor editor settings (same as VS Code settings.json).
        Written to ~/Library/Application Support/Cursor/User/settings.json.
      '';
      example = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "JetBrains Mono";
        "editor.tabSize" = 2;
      };
    };

    keybindings = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = ''
        Cursor keybindings (same as VS Code keybindings.json).
        Written to ~/Library/Application Support/Cursor/User/keybindings.json.
      '';
    };

    extensions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        VS Code extension IDs to install. Installed via `cursor --install-extension`
        on activation if not already present.
      '';
      example = [
        "vscodevim.vim"
        "esbenp.prettier-vscode"
        "rust-lang.rust-analyzer"
      ];
    };

    ai = {
      provider = mkOption {
        type = types.str;
        default = "anthropic";
        description = "AI provider for Cursor (anthropic, openai, etc.).";
      };

      model = mkOption {
        type = types.str;
        default = "claude-sonnet-4-20250514";
        description = "Default AI model for Cursor chat/composer.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install Cursor IDE
    home.packages = [ cfg.package ];

    # Deploy MCP config
    home.file.".cursor/mcp.json" = mkIf (cfg.mcp.servers != {}) {
      text = mcpServersJson;
    };

    # Deploy editor settings
    home.file."Library/Application Support/Cursor/User/settings.json" = mkIf (cfg.settings != {}) {
      text = settingsJson;
    };

    # Deploy keybindings
    home.file."Library/Application Support/Cursor/User/keybindings.json" = mkIf (cfg.keybindings != []) {
      text = keybindingsJson;
    };

    # Install extensions on activation
    home.activation.cursorExtensions = mkIf (cfg.extensions != [])
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${extensionInstallScript}
      '');
  };
}
