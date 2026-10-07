{
  aspects.virtualisation = {
    user.extraGroups = [ "libvirtd" ];

    nixos =
      { pkgs, ... }:
      {
        virtualisation = {
          # VM NICs: <interface type='user'><backend type='passt'/></interface>
          # NOTE: NAT (virbr0) would turn ip_forward back on (ANSSI R12)
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

          docker.rootless = {
            enable = true;
            setSocketVariable = true;
            daemon.settings.log-driver = "journald";
          };
        };

        programs.virt-manager.enable = true;
        programs.dconf.enable = true;

        environment.systemPackages = with pkgs; [
          virt-viewer
          spice-gtk
          docker-compose
          lazydocker
        ];

        preservation.preserveAt."/persistent".directories = [ "/var/lib/libvirt" ];
      };
  };
}
