{config, ...}: {
  aspects.minimal.includes = [config.aspects.lix];
  aspects.minimal.nixos = {
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = ["${modulesPath}/profiles/perlless.nix"];
    system.forbiddenDependenciesRegexes = lib.mkForce []; # perl-free activation
    environment.corePackages = lib.mkForce [pkgs.busybox];
    environment.stub-ld.enable = false;
    programs.nano.enable = false; # busybox carry vi

    documentation.man.man-db.enable = false;
    documentation.man.mandoc.enable = true;

    system.nixos-init.enable = true; # experimental rust init

    security.sudo.enable = false;
    security.doas.enable = true;

    nixpkgs.flake.setNixPath = false;
    nixpkgs.flake.setFlakeRegistry = false;
    nix.channel.enable = false;

    boot.bcache.enable = false;
    system.tools = lib.genAttrs ["nixos-option" "nixos-build-vms" "nixos-install" "nixos-enter"] (_: {enable = false;});
  };
}
