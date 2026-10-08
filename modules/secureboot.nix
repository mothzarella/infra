{ inputs, ... }: {
  aspects.secureboot.nixos =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      # corePackages is busybox-only (minimal aspect)
      environment.systemPackages = [
        (pkgs.symlinkJoin {
          name = "sbctl";
          paths = [ pkgs.sbctl ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/sbctl --prefix PATH : ${lib.makeBinPath [ pkgs.util-linux ]}
          '';
        })
      ];

      boot.loader = {
        efi.canTouchEfiVariables = true;
        timeout = 1;
        systemd-boot.enable = lib.mkForce false;
        systemd-boot.editor = false;
      };

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        configurationLimit = 8;

        autoGenerateKeys.enable = true;
        autoEnrollKeys.enable = true;
        autoEnrollKeys.autoReboot = true;
      };

      preservation.preserveAt."/persistent".directories = [ "/var/lib/sbctl" ];
    };
}
