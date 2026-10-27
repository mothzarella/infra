# no perl, python or extra tools in the live image
{
  aspects.iso.nixos =
    { lib, pkgs, ... }:
    {
      nixpkgs.overlays = lib.mkForce [ ]; # re-instantiates the external pkgs
      boot = {
        supportedFilesystems = {
          zfs = false;
          cifs = lib.mkForce false;
          xfs = lib.mkForce false;
        };
        swraid.enable = lib.mkForce false;
      };
      programs.git.package = pkgs.gitMinimal;
      documentation.enable = lib.mkForce false;
      environment.defaultPackages = lib.mkForce [ ];
      services.userborn.enable = true;
      system = {
        switch.enable = false; # immutable
        etc.overlay.enable = true;
        installer.channel.enable = false; # no nixpkgs copy
        extraDependencies = lib.mkForce [ ]; # no offline install
        disableInstallerTools = true;
        tools.nixos-install.enable = true;
        tools.nixos-enter.enable = true;
      };
    };
}
