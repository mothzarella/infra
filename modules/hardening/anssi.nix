{ inputs, ... }:
{
  aspects.hardening.nixos =
    { lib, ... }:
    {
      imports = [ "${inputs.securix}/modules/anssi" ];

      security = {
        anssi = {
          enable = true;
          level = "high";
          category = "client";
          rules.R5.implementation = "secureboot"; # lanzaboote
        };

        lockKernelModules = true;
        protectKernelImage = true;
      };

      boot.kernel.sysctl = {
        "kernel.modules_disabled" = lib.mkForce null;

        # https://github.com/cloud-gouv/securix/issues/286
        "net.ipv4.conf.*.rp_filter" = 1;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
      };
    };
}
