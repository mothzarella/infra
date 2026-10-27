{
  aspects.virtualisation = {
    nixos =
      { pkgs, ... }:
      {
        systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

        boot.kernelModules = [ "vxlan" ]; # k3s flannel

        environment.systemPackages = [
          pkgs.k3d
          pkgs.kubectl
          pkgs.kustomize
          pkgs.k9s
        ];
      };

    user.preserve.directories = [
      ".kube"
      ".config/k9s"
    ];
  };
}
