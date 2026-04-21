{
  description = "Blackmatter Cursor — declarative Cursor IDE provisioning (MCP servers, settings, extensions)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    guardrail = {
      url = "github:pleme-io/guardrail";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, substrate, guardrail, ... }:
    (import "${substrate}/lib/blackmatter-component-flake.nix") {
      inherit self nixpkgs;
      name = "blackmatter-cursor";
      description = "Declarative Cursor IDE provisioning";
      modules.homeManager = import ./module {
        skillHelpers = import "${substrate}/lib/hm-skill-helpers.nix" { lib = nixpkgs.lib; };
      };
      overlay = final: prev: {
        guardrail = guardrail.packages.${prev.stdenv.hostPlatform.system}.default;
        guardrail-rules = guardrail + "/rules";
      };
      autoEvalChecks = true;
    };
}
