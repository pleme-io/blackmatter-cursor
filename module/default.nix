# blackmatter-cursor — Declarative Cursor IDE provisioning
#
# Manages all Cursor config files from typed Nix options:
#   - settings.json (cursor.* options + VS Code settings)
#   - ~/.cursor/cli-config.json (CLI permissions + attribution)
#   - ~/.cursor/hooks.json (event hooks)
#   - .cursorignore / .cursorindexingignore
#   - ~/Applications/Cursor.app symlink (macOS Spotlight)
#   - Extension installation
#
# MCP servers come from blackmatter-anvil (not duplicated here).
{ skillHelpers }:
{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.blackmatter.components.cursor;
  cursorOpts = import ./cursor-options.nix { inherit lib; };

  # Skills via substrate helper
  skills = skillHelpers.mkSkills {
    skillsDir = ../skills;
    extraSkills = cfg.skills.extraSkills;
  };

  # Build settings.json from typed options + user overrides
  cursorSettings = {
    "cursor.general.enableShadowWorkspace" = cfg.cursor.general.enableShadowWorkspace;
    "cursor.general.gitGraphIndexing" = cfg.cursor.general.gitGraphIndexing;
    "cursor.composer.enabled" = cfg.cursor.composer.enable;
    "cursor.composer.agentMode" = cfg.cursor.composer.agentMode;
    "cursor.composer.suggestNextPrompt" = cfg.cursor.composer.suggestNextPrompt;
    "cursor.composer.shouldChimeAfterChatFinishes" = cfg.cursor.composer.shouldChimeAfterChatFinishes;
    "cursor.chat.model" = cfg.cursor.chat.model;
    "cursor.chat.smoothStreaming" = cfg.cursor.chat.smoothStreaming;
    "cursor.ai.model" = cfg.cursor.ai.model;
    "cursor.cpp.disabledLanguages" = cfg.cursor.tab.disabledLanguages;
    "cursor.cpp.enablePartialAccepts" = cfg.cursor.tab.enablePartialAccepts;
    "cursor.terminal.enableAiChecks" = cfg.cursor.terminal.enableAiChecks;
    "cursor.terminal.usePreviewBox" = cfg.cursor.terminal.usePreviewBox;
    "cursor.debug.timeoutPrevention" = cfg.cursor.debug.timeoutPrevention;
    "cursor.worktreeCleanupIntervalHours" = cfg.cursor.worktree.cleanupIntervalHours;
    "cursor.worktreeMaxCount" = cfg.cursor.worktree.maxCount;
    "telemetry.telemetryLevel" = if cfg.cursor.privacy.enableTelemetry then "all" else "off";
  }
  // optionalAttrs (cfg.cursor.composer.subagentModel != null) {
    "cursor.composer.subagentModel" = cfg.cursor.composer.subagentModel;
  }
  // optionalAttrs (cfg.cursor.composer.customChimeSoundPath != "") {
    "cursor.composer.customChimeSoundPath" = cfg.cursor.composer.customChimeSoundPath;
  }
  // optionalAttrs (cfg.cursor.general.globalCursorIgnoreList != []) {
    "cursor.general.globalCursorIgnoreList" = cfg.cursor.general.globalCursorIgnoreList;
  }
  // cfg.settings;

  cliConfig = {
    version = 1;
    permissions = {
      allow = cfg.cursor.cli.permissions.allow;
      deny = cfg.cursor.cli.permissions.deny;
    };
    attribution = {
      inherit (cfg.cursor.cli.attribution) attributeCommitsToAgent attributePRsToAgent;
    };
  };

  hooksConfig = { version = 1; hooks = cfg.cursor.hooks; };
  mcpServersJson = builtins.toJSON { mcpServers = cfg.mcp.servers; };

  extensionInstallScript = concatStringsSep "\n" (map (ext: ''
    if ! "${cfg.package}/bin/cursor" --list-extensions 2>/dev/null | grep -q "^${ext}$"; then
      "${cfg.package}/bin/cursor" --install-extension "${ext}" 2>/dev/null || true
    fi
  '') cfg.extensions);

in {
  options.blackmatter.components.cursor = {
    enable = mkEnableOption "Cursor IDE declarative configuration";

    # ── Skills (via substrate hm-skill-helpers) ────────────────────────
    skills = skillHelpers.mkSkillOptions;

    package = mkOption {
      type = types.package;
      default = pkgs.code-cursor;
      description = "Cursor IDE package.";
    };

    cursor = cursorOpts;

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional VS Code settings merged after typed cursor.* options.";
    };

    mcp.servers = mkOption {
      type = types.attrs;
      default = {};
      description = "Direct MCP servers (anvil writes ~/.cursor/mcp.json separately).";
    };

    keybindings = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Keybindings (VS Code keybindings.json format).";
    };

    extensions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extension IDs to install via cursor --install-extension.";
    };

    rules = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Content for ~/.cursorrules.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Core Cursor config ─────────────────────────────────────────────
    {
      home.packages = [ cfg.package ];

      home.activation.cursorApp = mkIf pkgs.stdenv.isDarwin
        (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/Applications"
          rm -f "$HOME/Applications/Cursor.app"
          ln -sf "${cfg.package}/Applications/Cursor.app" "$HOME/Applications/Cursor.app"
        '');

      home.file = mkMerge [
        (optionalAttrs (cfg.mcp.servers != {}) {
          ".cursor/mcp.json".text = mcpServersJson;
        })
        { "Library/Application Support/Cursor/User/settings.json".text = builtins.toJSON cursorSettings; }
        (optionalAttrs (cfg.keybindings != []) {
          "Library/Application Support/Cursor/User/keybindings.json".text = builtins.toJSON cfg.keybindings;
        })
        (optionalAttrs (cfg.cursor.cli.permissions.allow != [] || cfg.cursor.cli.permissions.deny != []) {
          ".cursor/cli-config.json".text = builtins.toJSON cliConfig;
        })
        (optionalAttrs (cfg.cursor.hooks != {}) {
          ".cursor/hooks.json".text = builtins.toJSON hooksConfig;
        })
        (optionalAttrs (cfg.rules != null) {
          ".cursorrules".text = cfg.rules;
        })
        (optionalAttrs (cfg.cursor.cursorignore != []) {
          ".cursorignore".text = concatStringsSep "\n" cfg.cursor.cursorignore + "\n";
        })
        (optionalAttrs (cfg.cursor.cursorindexingignore != []) {
          ".cursorindexingignore".text = concatStringsSep "\n" cfg.cursor.cursorindexingignore + "\n";
        })
      ];

      home.activation.cursorExtensions = mkIf (cfg.extensions != [])
        (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${extensionInstallScript}
        '');
    }

    # ── Skills (via substrate hm-skill-helpers) ──────────────────────
    (mkIf (cfg.skills.enable && skills.files != {}) {
      home.file = skills.homeFiles;
    })
  ]);
}
