{inputs, ...}: {
  aspects.lix.nixos = {pkgs, ...}: {
    nix.package = pkgs.lix;
    nix.settings.experimental-features = ["nix-command" "flakes" "pipe-operator"];
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.settings.nix-path = ["nixpkgs=${inputs.nixpkgs}"]; # nix-shell -p, <nixpkgs>
    nix.settings.allowed-users = ["@wheel"];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    nix.optimise.automatic = true;

    environment.systemPackages = [pkgs.gitMinimal];

    nix.settings.substituters = ["https://nix-community.cachix.org"];
    nix.settings.trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  };
}
