# toolchains per project: `use flake` in .envrc
{
  aspects.tar = {
    nixos =
      { config, pkgs, ... }:
      {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
          nix-direnv.package = pkgs.nix-direnv.override { nix = config.nix.package; }; # lix
        };
      };

    user.preserve.directories = [ ".local/share/direnv" ]; # allowed .envrc
  };
}
