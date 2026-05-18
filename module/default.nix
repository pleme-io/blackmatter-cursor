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

  # Platform-specific settings path
  isDarwin = pkgs.stdenv.isDarwin;
  settingsDir = if isDarwin
    then "Library/Application Support/Cursor/User"
    else ".config/Cursor/User";

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

    guardrail = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable guardrail defensive hooks for Cursor shell execution.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Core Cursor config ─────────────────────────────────────────────
    {
      home.packages = [ cfg.package ];

      home.activation.cursorApp = mkIf pkgs.stdenv.isDarwin
        (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/Applications"
          # macOS BSD `ln -sf` follows existing-symlink-to-dir at the
          # target path and creates the new link INSIDE the pointed-to
          # directory (e.g. .../Cursor.app/Cursor.app — fails permission-
          # denied on read-only nix store dirs). The `-n` flag makes
          # ln treat the target symlink as a regular file and replace
          # it atomically. Same flag works on GNU + BSD ln.
          ln -snf "${cfg.package}/Applications/Cursor.app" "$HOME/Applications/Cursor.app"
        '');

      home.file = mkMerge [
        (optionalAttrs (cfg.mcp.servers != {}) {
          ".cursor/mcp.json".text = mcpServersJson;
        })
        { "${settingsDir}/settings.json".text = builtins.toJSON cursorSettings; }
        (optionalAttrs (cfg.keybindings != []) {
          "${settingsDir}/keybindings.json".text = builtins.toJSON cfg.keybindings;
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

    # ── Guardrail defensive hooks ─────────────────────────────────────
    (mkIf cfg.guardrail.enable {
      blackmatter.components.cursor.cursor.hooks = {
        preToolUse = [{
          type = "command";
          command = "${pkgs.guardrail}/bin/guardrail check";
        }];
      };
    })

    # ── Anvil doctrine overlay ───────────────────────────────────────
    # Semantic keys from `anvil.translatedSettings.cursor` get mapped to
    # the corresponding typed `cursor.*` options via mkDefault. The
    # cursor-options.nix defaults already encode the doctrine value, so
    # this overlay is a no-op when doctrine is on (belt-and-suspenders
    # per operator decision: change-default AND overlay). It becomes
    # load-bearing if the standalone default ever drifts from anvil's
    # preferredModel — the overlay re-asserts anvil's value.
    #
    # Adding a new doctrine-controlled cursor knob: add the semantic key
    # to `anvil.translatedSettings.cursor`, then add a static line below
    # with `mkIf (t ? <key>) (mkDefault t.<key>)`.
    #
    # NOTE: structure is static (top-level keys are unconditional) — the
    # conditional inclusion uses `mkIf` *inside* the value, not
    # `optionalAttrs` around the structure. Using optionalAttrs at this
    # layer forces the module system to evaluate the condition while
    # extracting option paths, which cycles through
    # `config.blackmatter.components` (it needs cursor's own
    # contributions before it can read anvil's). mkIf inside the value
    # defers evaluation until the option is actually consumed.
    #
    # Also not gated on `cfg.enable` for the same recursion reason.
    (
      let
        t = config.blackmatter.components.anvil.translatedSettings.cursor or {};
      in {
        blackmatter.components.cursor.cursor.ai.model =
          mkIf (t ? aiModel) (mkDefault t.aiModel);
        blackmatter.components.cursor.cursor.chat.model =
          mkIf (t ? chatModel) (mkDefault t.chatModel);
      }
    )
  ]);
}
