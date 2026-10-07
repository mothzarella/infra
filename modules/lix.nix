{ inputs, ... }: {
  aspects.lix.nixos = { pkgs, ... }: {
    nix = {
      package = pkgs.lix;
      registry.nixpkgs.flake = inputs.nixpkgs;

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

    environment.systemPackages = [ pkgs.gitMinimal ];
  };
}
