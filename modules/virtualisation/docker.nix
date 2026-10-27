{
  aspects.virtualisation = {
    nixos =
      { pkgs, users, ... }:
      {
        systemd.user.services.docker.unitConfig.ConditionUser = map (u: "|${u}") users;

        # rootless docker
        boot.kernelModules = [
          "overlay"
          "bridge"
          "veth"
          "br_netfilter"
          "nft_chain_nat"
          "nft_compat"
          "xt_MASQUERADE"
          "xt_addrtype"
          "xt_conntrack"
          "xt_set"
        ];

        virtualisation.docker.rootless = {
          enable = true;
          setSocketVariable = true;
          daemon.settings.log-driver = "journald";
        };

        environment.systemPackages = [
          pkgs.docker-compose
          pkgs.lazydocker
        ];
      };

    user.preserve.directories = [ ".local/share/docker" ];
  };
}
