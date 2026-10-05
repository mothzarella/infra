{
  aspects.lix.nixos = {pkgs, ...}: {
    nix.package = pkgs.lix;
    nix.settings.experimental-features = ["nix-command" "flakes" "pipe-operator"];

    nix.settings.substituters = ["https://nix-community.cachix.org"];
    nix.settings.trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  };
}
