{
  description = "Declarative Cursor IDE provisioning — MCP servers, settings, extensions";

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

  outputs = { self, nixpkgs, substrate, guardrail, ... }: {
    overlays.default = final: prev: {
      guardrail = guardrail.packages.${prev.stdenv.hostPlatform.system}.default;
      guardrail-rules = guardrail + "/rules";
    };

    homeManagerModules.default = import ./module {
      skillHelpers = import "${substrate}/lib/hm-skill-helpers.nix" { lib = nixpkgs.lib; };
    };
  };
}
