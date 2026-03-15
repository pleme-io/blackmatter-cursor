{
  description = "Declarative Cursor IDE provisioning — MCP servers, settings, extensions";

  outputs = { self, ... }: {
    homeManagerModules.default = import ./module;
  };
}
