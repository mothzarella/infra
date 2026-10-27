{
  aspects.base.nixos = {
    nix.daemonCPUSchedPolicy = "idle";
    nix.daemonIOSchedClass = "idle";

    zramSwap.enable = true;
    boot = {
      bcache.enable = false;
      kernel.sysctl = {
        "vm.swappiness" = 180; # zram > dropping page cache
        "vm.page-cluster" = 0; # no swap readahead on zram
      };
    };
  };
}
