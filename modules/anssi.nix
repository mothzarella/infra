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

    # https://github.com/cloud-gouv/securix/issues/286
    boot.kernel.sysctl = {
      "net.ipv4.conf.*.rp_filter" = 1;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
    };
  };
}
