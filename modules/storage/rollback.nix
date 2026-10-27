{
  aspects.storage.nixos.boot.initrd.systemd.services.rollback = {
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@cryptroot.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";

    script = ''
      shopt -s nullglob
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/cryptroot /mnt

      if [[ -e /mnt/root ]]; then
        mkdir -p /mnt/old_roots
        mv /mnt/root "/mnt/old_roots/$(date -d "@$(stat -c %Y /mnt/root)" +%F_%T)"
      fi

      cutoff=$(date -d '-30 days' +%s)
      for old in /mnt/old_roots/*; do
        if (($(stat -c %Y "$old") < cutoff)); then
          btrfs subvolume delete -R "$old"
        fi
      done

      btrfs subvolume create /mnt/root
      umount /mnt
    '';
  };
}
