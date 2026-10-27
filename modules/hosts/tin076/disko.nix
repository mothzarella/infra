# this disk on the shared layout (storage aspect)
{
  aspects.tin076.nixos.disko.devices.disk.main = {
    device = "/dev/disk/by-id/nvme-KINGSTON_SNV2S1000G_50026B728358322A";
    content.partitions.root.content.settings.bypassWorkqueues = true; # NVMe
    content.partitions.swap = {
      size = "4G";
      content = {
        type = "swap";
        randomEncryption = true;
        discardPolicy = "both";
      };
    };
  };
}
