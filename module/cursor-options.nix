# Cursor IDE configuration options — typed schema matching settings.json + config files
#
# Every option maps to a Cursor setting key. Types enforced by Nix module system.
# Sources: cursor.com/docs, app bundle analysis, state.vscdb inspection.
{ lib, ... }:
with lib;
{
  # ── cursor.general.* ─────────────────────────────────────────────
  general = {
    enableShadowWorkspace = mkOption {
      type = types.bool;
      default = false;
      description = "Enable shadow workspace for background agent operations.";
    };

    gitGraphIndexing = mkOption {
      type = types.bool;
      default = false;
      description = "Enable git graph indexing for enhanced context.";
    };

    globalCursorIgnoreList = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Global .cursorignore patterns (gitignore syntax).";
      example = [ "node_modules" ".git" "target" ];
    };
  };

  # ── cursor.composer.* ───────────────────────────────────────────
  composer = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Composer/Agent panel.";
    };

    agentMode = mkOption {
      type = types.bool;
      default = true;
      description = "Default to Agent mode (vs Ask mode).";
    };

    suggestNextPrompt = mkOption {
      type = types.bool;
      default = true;
      description = "Suggest follow-up prompts after responses.";
    };

    shouldChimeAfterChatFinishes = mkOption {
      type = types.bool;
      default = false;
      description = "Play sound when chat completes.";
    };

    customChimeSoundPath = mkOption {
      type = types.str;
      default = "";
      description = "Custom chime sound file path.";
    };

    subagentModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Model for subagents (null = same as main model).";
    };
  };

  # ── cursor.chat.* ───────────────────────────────────────────────
  chat = {
    model = mkOption {
      type = types.str;
      default = "auto";
      description = "Default chat model ID.";
      example = "claude-opus-4-6";
    };

    smoothStreaming = mkOption {
      type = types.bool;
      default = true;
      description = "Smooth streaming of chat responses.";
    };
  };

  # ── cursor.ai.* ─────────────────────────────────────────────────
  ai = {
    model = mkOption {
      type = types.str;
      default = "auto";
      description = "Default AI model for all Cursor operations.";
      example = "claude-opus-4-6";
    };
  };

  # ── cursor.cpp.* (Tab completions) ──────────────────────────────
  tab = {
    disabledLanguages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Languages where Tab completion is disabled.";
      example = [ "markdown" "plaintext" ];
    };

    enablePartialAccepts = mkOption {
      type = types.bool;
      default = true;
      description = "Enable partial Tab accepts (word-by-word with Ctrl+Right).";
    };
  };

  # ── cursor.terminal.* ───────────────────────────────────────────
  terminal = {
    enableAiChecks = mkOption {
      type = types.bool;
      default = true;
      description = "Enable AI terminal command checks.";
    };

    usePreviewBox = mkOption {
      type = types.bool;
      default = true;
      description = "Use preview box for terminal AI commands.";
    };
  };

  # ── cursor.debug.* ──────────────────────────────────────────────
  debug = {
    timeoutPrevention = mkOption {
      type = types.enum [ "local_only" "always" "never" ];
      default = "local_only";
      description = "Prevent connection timeout errors during debugging.";
    };
  };

  # ── cursor.worktree.* ───────────────────────────────────────────
  worktree = {
    cleanupIntervalHours = mkOption {
      type = types.int;
      default = 6;
      description = "Worktree cleanup interval in hours.";
    };

    maxCount = mkOption {
      type = types.int;
      default = 20;
      description = "Maximum worktrees per workspace.";
    };
  };

  # ── Privacy ──────────────────────────────────────────────────────
  privacy = {
    enableTelemetry = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Cursor telemetry/usage data collection.";
    };
  };

  # ── CLI config (~/.cursor/cli-config.json) ───────────────────────
  cli = {
    permissions = {
      allow = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Allowed CLI agent operations (Shell, Read, Write, Mcp patterns).";
        example = [ "Shell(git *)" "Read(**/*.rs)" "Write(src/**)" "Mcp(github:*)" ];
      };

      deny = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Denied CLI agent operations.";
        example = [ "Shell(rm -rf *)" ];
      };
    };

    attribution = {
      attributeCommitsToAgent = mkOption {
        type = types.bool;
        default = false;
        description = "Add agent attribution to git commits.";
      };

      attributePRsToAgent = mkOption {
        type = types.bool;
        default = false;
        description = "Add agent attribution to pull requests.";
      };
    };
  };

  # ── Hooks (~/.cursor/hooks.json) ─────────────────────────────────
  hooks = mkOption {
    type = types.attrs;
    default = {};
    description = ''
      Cursor hooks configuration. Keys are event names, values are lists of hook definitions.
      Events: sessionStart, sessionEnd, preToolUse, postToolUse, beforeShellExecution,
      afterShellExecution, beforeMCPExecution, afterMCPExecution, beforeReadFile,
      afterFileEdit, beforeSubmitPrompt, stop, afterAgentResponse.
    '';
    example = {
      preToolUse = [
        { command = "/path/to/script.sh"; type = "command"; timeout = 30; }
      ];
    };
  };

  # ── Ignore patterns ──────────────────────────────────────────────
  cursorignore = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "Patterns for .cursorignore (exclude from AI + indexing).";
    example = [ "vendor/" "node_modules/" ".git/" "target/" ];
  };

  cursorindexingignore = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "Patterns for .cursorindexingignore (exclude from indexing only).";
    example = [ "*.lock" "Cargo.nix" ];
  };
}
