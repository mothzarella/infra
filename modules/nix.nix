{ inputs, ... }:
{
  aspects.nix.nixos =
    { pkgs, ... }:
    {
      imports = [ "${inputs.fix}/nix/modules/nixos.nix" ];

      nix = {
        package = pkgs.lix;
        channel.enable = false;
        registry.nixpkgs.flake = inputs.nixpkgs; # locked (narHash, rev)

        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "pipe-operator"
          ];
          nix-path = [ "nixpkgs=${inputs.nixpkgs}" ]; # nix-shell -p, <nixpkgs>
          allowed-users = [ "@wheel" ];

          min-free = 5 * 1024 * 1024 * 1024;
          max-free = 15 * 1024 * 1024 * 1024;
          connect-timeout = 5;
          fallback = true;
          warn-dirty = false;

          substituters = [ "https://nix-community.cachix.org" ];
          trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
        };

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };
        optimise.automatic = true;
      };

      nixpkgs.flake.setNixPath = false; # nix-path in nix.conf (NIX_PATH needs a relogin)

      programs.fix.enable = true;
      environment.shellAliases.fix = "NIX_CONFIG='extra-experimental-features = pipe-operators' fix";

      environment.systemPackages = [ pkgs.gitMinimal ]; # flakes
    };
}
