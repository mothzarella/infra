{
  aspects.virtualisation = {
    user.extraGroups = [ "libvirtd" ];

    nixos =
      { pkgs, ... }:
      {
        virtualisation = {
          libvirtd = {
            enable = true;
            onBoot = "ignore";
            onShutdown = "shutdown";
            qemu = {
              package = pkgs.qemu_kvm;
              runAsRoot = false;
              swtpm.enable = true;
            };
          };
          spiceUSBRedirection.enable = true;
        };

        boot.kernelModules = [
          "vhost_net"
          "bridge"
          "nft_masq"
          "nft_reject_inet"
          "nft_chain_nat"
        ];

        programs.virt-manager.enable = true;
        programs.dconf.enable = true;

        environment.systemPackages = [
          pkgs.virt-viewer
          pkgs.spice-gtk
        ];

        preservation.preserveAt."/persistent".directories = [ "/var/lib/libvirt" ];
      };
  };
}
