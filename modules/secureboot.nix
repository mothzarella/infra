{inputs, ...}: {
  aspects.secureboot.nixos = {
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.lanzaboote.nixosModules.lanzaboote];

    environment.systemPackages = [pkgs.sbctl];

    boot = {
      loader.efi.canTouchEfiVariables = true;
      loader.timeout = 1;
      loader.systemd-boot.enable = lib.mkForce false;
      loader.systemd-boot.editor = false;

      lanzaboote.enable = true;
      lanzaboote.pkiBundle = "/var/lib/sbctl";
      lanzaboote.configurationLimit = 8;

      lanzaboote.autoGenerateKeys.enable = true;
      lanzaboote.autoEnrollKeys.enable = true;
      lanzaboote.autoEnrollKeys.autoReboot = true;
    };

    preservation.preserveAt."/persistent".directories = ["/var/lib/sbctl"];
  };
}
