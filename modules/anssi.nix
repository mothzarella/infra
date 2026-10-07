{ inputs, ... }: {
  aspects.anssi.nixos = {
    # ANSSI-BP-028 rules from securix
    imports = [ "${inputs.securix}/modules/anssi" ];

    security.anssi = {
      enable = true;
      level = "intermediary";
      category = "client";
      rules.R5.implementation = "secureboot"; # lanzaboote
    };

    security.protectKernelImage = true; # no kexec, no hibernation
  };
}
