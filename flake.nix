{
  description = "$REPO_NAME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    antea.url = "git+https://source.fetsorn.website/fetsorn/antea";
    beams.url = "git+https://source.fetsorn.website/fetsorn/beams?ref=main";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      eachSystem = systems: f:
        let
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key:
                let
                  appendSystem = key: system: ret: { ${system} = ret.${key}; };
                in attrs // {
                  ${key} = (attrs.${key} or { })
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
      let
        pkgs = import nixpkgs { inherit system; };
        llines = (with pkgs;
          stdenv.mkDerivation rec {
            pname = "lifelines";
            version = "unstable-2021-11-22";

            src = fetchFromGitHub {
              owner = pname;
              repo = pname;
              rev = "a5a54e8";
              sha256 = "tqggAcYRRxtPjTLc+YJphYWdqfWxMG8V/cBOpMTiZ9I=";
            };

            buildInputs = [ gettext libiconv ncurses perl ];
            nativeBuildInputs = [ autoreconfHook bison ];

            meta = with lib; {
              description = "Genealogy tool with ncurses interface";
              homepage = "https://lifelines.github.io/lifelines/";
              license = licenses.mit;
              platforms = platforms.darwin;
            };
          });
      in rec {
        devShell = pkgs.mkShell {
          buildInputs = [
            inputs.antea.packages.${system}.timeline-backend-local
            llines
            pkgs.recutils
            pkgs.coreutils
            pkgs.parallel
            pkgs.file
            pkgs.csvkit
            pkgs.moreutils
          ];
          shellHook = ''
            ln -s ${inputs.beams.packages.${system}.beams}/bin scripts
          '';
        };
      });
}
