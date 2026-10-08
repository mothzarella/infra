{ config, ... }: {
  aspects.chromium = {
    includes = with config.aspects; [
      searxng
      xdg
    ];

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

        # chromium-web-store (ocaahdebbfolfmndjeplogmgcagdmblk)
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
              unzip -qq $src -d $out || [ $? -eq 1 ]
              jq '.key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqF/d41Q7agjkUzYq8ZGbQr8XW8mmEIMXOnR1uCTnYLL+Dm9Z+LO50xZukOISNy6zFxpI8ts/OGLsm+I2x9+UprUU4/EVdmxuwegFE6NBoEhHoRNYY0gbXZkaU8YY/XwzjVY/k18DDhl5NYPEnF6uq4Oyidg+xtd3W4+iGYczuOLER1Tp5y614zOTphcvFYhvUkCijQ6HT1TtRq/34SlFoRQqo4SFiLriK451xWIcfwiMLIekWrdoQa1v8dqIlMA3r6CKc0QykJpSYbiyormWiZ0hl2HLpkZ85mD9V0eDQ5RCtb6vkybK7INcq4yKQV4YkXhr9NpX9U4re4dlFQjEJQIDAQAB"' \
                $out/manifest.json > manifest.json
              mv manifest.json $out/manifest.json
            '';

        # Wappalyzer (gppongmhjkpfnbhagpmjfkannfbllamg)
        wappalyzer =
          pkgs.runCommand "wappalyzer"
            {
              src = pkgs.fetchurl {
                name = "wappalyzer-6.12.7.crx";
                url = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=143.0&acceptformat=crx3&x=id%3Dgppongmhjkpfnbhagpmjfkannfbllamg%26uc";
                hash = "sha256-5KjIEBHM+zyZDbQGHn7X/zIPM68s2vBw000ZSzIk28A="; # latest
              };
              nativeBuildInputs = [
                pkgs.unzip
                pkgs.jq
              ];
            }
            ''
              unzip -qq $src -d $out || [ $? -eq 1 ]
              jq '.key = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDTx6NfXtZyfrF1kTv+h0o1P0yovMsOKjocLmo+8eCQmrGS4FayUspVq/UtL0zbKnK3xXW1kfGVkOAy5TfZ6fUMoHWF7NyXEsvD+jQ6HLDOkHq/VDcN6i5hJhmYORwdFNhBAmYZY0ORd65AR2wHlxJoCRuyz25Ys/rxMaQad/zHHwIDAQAB"' \
                $out/manifest.json > manifest.json
              mv manifest.json $out/manifest.json

              substituteInPlace $out/js/index.js $out/js/options.js \
                --replace-fail "'tracking', true" "'tracking', false" \
                --replace-fail "'upgradeMessage', true" "'upgradeMessage', false"
            '';

        chromium = pkgs.ungoogled-chromium.override {
          commandLineArgs = [
            "--ozone-platform=wayland"
            "--load-extension=${ublock},${webStore},${wappalyzer}"
            "--extension-mime-request-handling=always-prompt-for-install"
            "--no-default-browser-check"
            "--disable-backgrounding-occluded-windows"

            # privacy
            "--disable-search-engine-collection"
            "--fingerprinting-canvas-image-data-noise"
            "--fingerprinting-canvas-measuretext-noise"
            "--fingerprinting-client-rects-noise"
            "--no-pings"
            "--webrtc-ip-handling-policy=default_public_interface_only" # no LAN IP leak

            "--force-punycode-hostnames"

            # VA-API decode
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
          enable = true;
          extraOpts = {
            RestoreOnStartup = 1;

            BlockThirdPartyCookies = true;
            SearchSuggestEnabled = false;
            DefaultSearchProviderEnabled = true;
            DefaultSearchProviderName = "SearXNG";
            DefaultSearchProviderKeyword = "sx";
            DefaultSearchProviderSearchURL = "http://localhost:8888/search?q={searchTerms}";
            HttpAllowlist = [ "localhost" ];
            NetworkPredictionOptions = 2;
            PrivacySandboxPromptEnabled = false;
            PrivacySandboxAdTopicsEnabled = false;
            PrivacySandboxSiteEnabledAdsEnabled = false;
            PrivacySandboxAdMeasurementEnabled = false;
            MetricsReportingEnabled = false;
            UrlKeyedAnonymizedDataCollectionEnabled = false;
            SpellCheckServiceEnabled = false;
            AlternateErrorPagesEnabled = false;

            "3rdparty".extensions.aagbfnajcjecmdlogmofkijaeohmkpnk = {
              userSettings = [
                [
                  "webrtcIPAddressHidden"
                  "true"
                ]
              ];
              toOverwrite.filterLists = [
                # defaults
                "ublock-filters"
                "ublock-badware"
                "ublock-privacy"
                "ublock-unbreak"
                "ublock-quick-fixes"
                "easylist"
                "easyprivacy"
                "urlhaus-1"
                "plowe-0"

                "adguard-spyware-url" # tracking params in links
                "block-lan"
                "curben-phishing"
                "fanboy-social"
                "fanboy-cookiemonster"
                "ublock-cookies-easylist"
                "ITA-0"
              ];
            };

            HttpsOnlyMode = "force_enabled";
            PasswordManagerEnabled = false; # no keyring
            AutofillCreditCardEnabled = false;
            AutofillAddressEnabled = false;

            HighEfficiencyModeEnabled = true; # discard inactive tabs
            MemorySaverModeSavings = 1; # balanced
            BatterySaverModeAvailability = 1;
            BackgroundModeEnabled = false;
          };

          initialPrefs.vertical_tabs.enabled = true;
        };

        environment.systemPackages = [ chromium ];
        environment.sessionVariables.BROWSER = lib.getExe chromium;

        preservation.preserveAt."/persistent".users = lib.genAttrs users (_: {
          directories = [ ".config/chromium" ];
        });
      };
  };
}
