{
  aspects.hardening.nixos.boot = {
    kernelParams = [
      "debugfs=off"
      "vsyscall=none"
      "iommu.strict=1"
    ];

    kernel.sysctl = {
      "kernel.io_uring_disabled" = 2;
      "dev.tty.ldisc_autoload" = 0;
    };

    blacklistedKernelModules = [
      "ax25"
      "netrom"
      "rose"

      "adfs"
      "affs"
      "bfs"
      "befs"
      "cramfs"
      "efs"
      "freevxfs"
      "hpfs"
      "jfs"
      "minix"
      "nilfs2"
      "omfs"
      "qnx4"
      "qnx6"
      "sysv"
      "ufs"
    ];
  };
}
