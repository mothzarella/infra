{
  aspects.remote.nixos = {
    services.openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        PermitRootLogin = "prohibit-password"; # nixos-rebuild --target-host root@
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQTSE+nSOkApRkHkb43vEmgond9ABf7KLEcxoD9E/dZ git@mothzarella.dev"
    ];
  };
}
