# this disk on the shared layout (storage aspect)
{
  aspects.kiwi.nixos =
    { lib, ... }:
    {
      disko.devices.disk.main = {
        device = "/dev/disk/by-id/ata-Teclast_128GB_NA850-2280_AA000000000112608242";
        content.partitions.root.content.settings.bypassWorkqueues = true; # SSD
        # weak CPU
        content.partitions.root.content.content.subvolumes = {
          "/root".mountOptions = lib.mkForce [
            "compress=zstd:1"
            "noatime"
          ];
          "/nix".mountOptions = lib.mkForce [
            "compress=zstd:1"
            "noatime"
          ];
          "/persistent".mountOptions = lib.mkForce [
            "compress=zstd:1"
            "noatime"
          ];
        };
      };
    };
}
