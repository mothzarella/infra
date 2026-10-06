{config, ...}: {
  aspects.chromium.includes = [config.aspects.xdg];

  aspects.chromium.user.mimeApps = {
    "text/html" = "chromium-browser.desktop";
    "x-scheme-handler/http" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
  };

  aspects.chromium.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # uBlock Origin (MV2)
    ublock = pkgs.fetchzip rec {
      pname = "ublock-origin";
      version = "1.75.0";
      url = "https://github.com/gorhill/uBlock/releases/download/${version}/uBlock0_${version}.chromium.zip";
      postFetch = ''
        ${lib.getExe pkgs.jq} '.key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoPzDalQbv6D74KSsEZslYNg6zUlKrtYq1LBfIZYgHWnHe4DFsH5P2uWe4r2SPyjUjDlqfHf2qYOo0L0g4A1xQfwAXnFWIPlp/iaGn1aXpR1gfA8d0dgtIP84I2/Mjp5I/lSfmoGE/Aasx7/z4sZcZ1LpRN77fK/tfItU3EZPpusigaqQgbl+6dYck3RTNW8Zkx6KNLzN6Qan3u6noPGNA63YvfT3AT5Iaqs5U+cFUi00WVqHClNG3likRVlv8I53PobAobefWogA+fhCneZKKCR3ywRTMZ4tZ2enYI5BQ6ztATY2xreYQ2OBgzUjXaoHr9HhJyly4iVZRAHMow/kFQIDAQAB"' \
          $out/manifest.json > manifest.json
        mv manifest.json $out/manifest.json
      ''; # id aagbfnajcjecmdlogmofkijaeohmkpnk
      hash = "sha256-oF1TBOYaG31n1uU1xEf1yJRJYBJNgxwX02Vi1+wGxJA=";
    };

    chromium = pkgs.ungoogled-chromium.override {
      commandLineArgs = [
        "--ozone-platform=wayland" # no XWayland
        "--load-extension=${ublock}"
        "--force-dark-mode" # dark UI, prefers-color-scheme: dark
      ];
    };
  in {
    environment.systemPackages = [chromium];
    environment.sessionVariables.BROWSER = lib.getExe chromium;

    preservation.preserveAt."/persistent".users =
      config.users.users
      |> lib.filterAttrs (_: u: u.isNormalUser)
      |> lib.mapAttrs (_: _: {directories = [".config/chromium"];});
  };
}
