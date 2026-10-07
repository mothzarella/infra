{ config, ... }: {
  aspects.chromium = {
    includes = [ config.aspects.xdg ];

    user.mimeApps = {
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
    };

    nixos =
      {
        lib,
        pkgs,
        users,
        ...
      }:
      let
        # uBlock Origin MV2 (aagbfnajcjecmdlogmofkijaeohmkpnk)
        ublock = pkgs.fetchzip rec {
          pname = "ublock-origin";
          version = "1.75.0";
          url = "https://github.com/gorhill/uBlock/releases/download/${version}/uBlock0_${version}.chromium.zip";
          postFetch = ''
            ${lib.getExe pkgs.jq} '.key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoPzDalQbv6D74KSsEZslYNg6zUlKrtYq1LBfIZYgHWnHe4DFsH5P2uWe4r2SPyjUjDlqfHf2qYOo0L0g4A1xQfwAXnFWIPlp/iaGn1aXpR1gfA8d0dgtIP84I2/Mjp5I/lSfmoGE/Aasx7/z4sZcZ1LpRN77fK/tfItU3EZPpusigaqQgbl+6dYck3RTNW8Zkx6KNLzN6Qan3u6noPGNA63YvfT3AT5Iaqs5U+cFUi00WVqHClNG3likRVlv8I53PobAobefWogA+fhCneZKKCR3ywRTMZ4tZ2enYI5BQ6ztATY2xreYQ2OBgzUjXaoHr9HhJyly4iVZRAHMow/kFQIDAQAB"' \
              $out/manifest.json > manifest.json
            mv manifest.json $out/manifest.json
          '';
          hash = "sha256-oF1TBOYaG31n1uU1xEf1yJRJYBJNgxwX02Vi1+wGxJA=";
        };

        # NeverDecaf/chromium-web-store (ocaahdebbfolfmndjeplogmgcagdmblk)
        webStore =
          pkgs.runCommand "chromium-web-store"
            {
              src = pkgs.fetchurl {
                url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.5.4/Chromium.Web.Store.crx";
                hash = "sha256-Y8B1tKJbEa8sU22tGRlG6NlUf5LVtsJXss5BONKZbzI=";
              };
              nativeBuildInputs = [
                pkgs.unzip
                pkgs.jq
              ];
            }
            ''
              unzip -qq $src -d $out || [ $? -eq 1 ] # crx header reads as leading junk
              jq '.key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqF/d41Q7agjkUzYq8ZGbQr8XW8mmEIMXOnR1uCTnYLL+Dm9Z+LO50xZukOISNy6zFxpI8ts/OGLsm+I2x9+UprUU4/EVdmxuwegFE6NBoEhHoRNYY0gbXZkaU8YY/XwzjVY/k18DDhl5NYPEnF6uq4Oyidg+xtd3W4+iGYczuOLER1Tp5y614zOTphcvFYhvUkCijQ6HT1TtRq/34SlFoRQqo4SFiLriK451xWIcfwiMLIekWrdoQa1v8dqIlMA3r6CKc0QykJpSYbiyormWiZ0hl2HLpkZ85mD9V0eDQ5RCtb6vkybK7INcq4yKQV4YkXhr9NpX9U4re4dlFQjEJQIDAQAB"' \
                $out/manifest.json > manifest.json
              mv manifest.json $out/manifest.json
            '';

        chromium = pkgs.ungoogled-chromium.override {
          commandLineArgs = [
            "--ozone-platform=wayland"
            "--load-extension=${ublock},${webStore}"
            "--extension-mime-request-handling=always-prompt-for-install" # crx installs for the web store
            "--no-default-browser-check"

            # privacy
            "--disable-search-engine-collection"
            "--fingerprinting-canvas-image-data-noise"
            "--fingerprinting-canvas-measuretext-noise"
            "--fingerprinting-client-rects-noise"
            "--no-pings"
            "--webrtc-ip-handling-policy=default_public_interface_only" # no LAN IP leak

            # security
            "--force-punycode-hostnames" # no homograph domains

            # VA-API decode is on by default on Wayland since 143
            "--enable-features=${
              lib.concatStringsSep "," [
                "VerticalTabs"
                "ReducedSystemInfo"
                "RemoveClientHints"
                "SpoofWebGLInfo"
                "NoCrossOriginReferrers"
                "AcceleratedVideoEncoder"
              ]
            }"
          ];
        };
      in
      {
        programs.chromium = {
          enable = true; # policies in /etc/chromium
          extraOpts = {
            # privacy
            BlockThirdPartyCookies = true;
            SearchSuggestEnabled = false; # keystrokes to the search engine
            NetworkPredictionOptions = 2; # no preloading of unvisited pages
            PrivacySandboxPromptEnabled = false;
            PrivacySandboxAdTopicsEnabled = false;
            PrivacySandboxSiteEnabledAdsEnabled = false;
            PrivacySandboxAdMeasurementEnabled = false;

            # security
            HttpsOnlyMode = "force_enabled";
            PasswordManagerEnabled = false; # no keyring
            AutofillCreditCardEnabled = false;
            AutofillAddressEnabled = false;

            # performance
            HighEfficiencyModeEnabled = true; # memory saver (discard inactive tabs)
            MemorySaverModeSavings = 1; # balanced
            BatterySaverModeAvailability = 1; # low battery (throttle frames and background)
            BackgroundModeEnabled = false; # nothing left running after closing
          };
          initialPrefs.vertical_tabs.enabled = true; # new profiles only
        };

        environment.systemPackages = [ chromium ];
        environment.sessionVariables.BROWSER = lib.getExe chromium;

        preservation.preserveAt."/persistent".users = lib.genAttrs users (_: {
          directories = [ ".config/chromium" ];
        });
      };
  };
}
