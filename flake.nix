{
  description = "$REPO_NAME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    csvs-ui.url = "git+https://source.fetsorn.website/fetsorn/csvs-ui?ref=main";
    csvs-sh.url = "git+https://source.fetsorn.website/fetsorn/csvs-sh?ref=main";
  };
  outputs = inputs@{ nixpkgs, ... }:
    let
      eachSystem = systems: f:
        let
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key:
                let
                  appendSystem = key: system: ret: { $${system} = ret.$${key}; };
                in attrs // {
                  $${key} = (attrs.$${key} or { })
                    // (appendSystem key system ret);
                };
            in builtins.foldl' op attrs (builtins.attrNames ret);
        in builtins.foldl' op { } systems;
      defaultSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in eachSystem defaultSystems (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            inputs.csvs-ui.packages.$${system}.csvs-ui-backend-local
            inputs.csvs-sh.packages.$${system}.csvs-sh
            pkgs.git-lfs
          ];
          shellHook = ''
            export LC_ALL=ru_RU.utf-8
          '';
        };
      });
}
