{ inputs, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in
{
  flake.formatter.x86_64-linux = pkgs.treefmt.withConfig {
    runtimeInputs = [
      pkgs.statix
      pkgs.deadnix
      pkgs.nixfmt
      pkgs.yamlfmt
    ];

    settings = {
      on-unmatched = "info";

      formatter = {
        statix = {
          command = "sh";
          options = [
            "-euc"
            ''for f; do statix fix "$f" && statix check "$f"; done'' # one path per call, W20 has no autofix
            "--"
          ];
          includes = [ "*.nix" ];
          priority = 1;
        };

        deadnix = {
          command = "deadnix";
          options = [ "--edit" ];
          includes = [ "*.nix" ];
          priority = 2;
        };

        nixfmt = {
          command = "nixfmt";
          includes = [ "*.nix" ];
          priority = 3;
        };

        yamlfmt = {
          command = "yamlfmt";
          options = [
            "-formatter"
            "retain_line_breaks_single=true"
          ];
          includes = [ "*.yml" ];
        };
      };
    };
  };
}
