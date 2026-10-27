{ config, ... }:
{
  aspects.base = {
    includes = [
      config.aspects.nix
      config.aspects.hardening
      config.aspects.storage
      config.aspects.secrets
      config.aspects.xdg
    ];

    nixos =
      {
        lib,
        pkgs,
        modulesPath,
        ...
      }:
      {
        imports = [ "${modulesPath}/profiles/perlless.nix" ];

        system = {
          forbiddenDependenciesRegexes = lib.mkForce [ ]; # perl-free activation
          nixos-init.enable = true;
          tools = {
            nixos-option.enable = false;
            nixos-build-vms.enable = false;
            nixos-install.enable = false;
            nixos-enter.enable = false;
          };
        };

        environment = {
          corePackages = lib.mkForce [ pkgs.busybox ];
          stub-ld.enable = false;
        };

        programs.nano.enable = false;
        programs.nix-ld.enable = true;

        documentation.man.man-db.enable = false;
        documentation.man.mandoc.enable = true;

        security.sudo.enable = false;
        security.doas.enable = true;
      };
  };
}
