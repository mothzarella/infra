{
  aspects.searxng.nixos =
    { lib, pkgs, ... }:
    {
      services.searx = {
        enable = true;
        package = pkgs.searxng;
        settings = {
          server = {
            bind_address = "127.0.0.1";
            port = 8888;
            secret_key = "$SEARX_SECRET_KEY";
            image_proxy = true;
            method = "GET";
          };
          outgoing.request_timeout = 5.0; # the VPN adds latency
        };
      };

      systemd.services.searx-init.script = lib.mkBefore ''
        export SEARX_SECRET_KEY=$(${lib.getExe pkgs.openssl} rand -hex 32)
      '';
    };
}
