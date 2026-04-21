# blackmatter-cursor

Declarative Cursor IDE provisioning via home-manager — settings, extensions,
MCP server definitions (via `blackmatter-anvil`), and guardrails.

## Usage

```nix
{
  inputs.blackmatter-cursor.url = "github:pleme-io/blackmatter-cursor";

  outputs = { blackmatter-cursor, ... }: {
    homeConfigurations.you = home-manager.lib.homeManagerConfiguration {
      modules = [
        blackmatter-cursor.homeManagerModules.default
        ({ ... }: {
          blackmatter.components.cursor = {
            enable = true;
            theme = "nord";
            mcpServers = [ "github" "grafana" ];
          };
        })
      ];
    };
  };
}
```

## What it does

- Renders `~/Library/Application Support/Cursor/User/settings.json`
- Installs the declared extension set
- Wires shared MCP servers via `blackmatter-anvil`
- Pulls in `guardrail` rules to constrain agent behavior

## License

MIT
