{
  aspects.browser.nixos =
    { lib, pkgs, ... }:
    let
      # uBlock Origin MV2 (aagbfnajcjecmdlogmofkijaeohmkpnk)
      ublockVersion = "1.75.0";
      ublock = pkgs.fetchzip {
        pname = "ublock-origin";
        version = ublockVersion;
        url = "https://github.com/gorhill/uBlock/releases/download/${ublockVersion}/uBlock0_${ublockVersion}.chromium.zip";
        postFetch = ''
          ${lib.getExe pkgs.jq} '.key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoPzDalQbv6D74KSsEZslYNg6zUlKrtYq1LBfIZYgHWnHe4DFsH5P2uWe4r2SPyjUjDlqfHf2qYOo0L0g4A1xQfwAXnFWIPlp/iaGn1aXpR1gfA8d0dgtIP84I2/Mjp5I/lSfmoGE/Aasx7/z4sZcZ1LpRN77fK/tfItU3EZPpusigaqQgbl+6dYck3RTNW8Zkx6KNLzN6Qan3u6noPGNA63YvfT3AT5Iaqs5U+cFUi00WVqHClNG3likRVlv8I53PobAobefWogA+fhCneZKKCR3ywRTMZ4tZ2enYI5BQ6ztATY2xreYQ2OBgzUjXaoHr9HhJyly4iVZRAHMow/kFQIDAQAB"' \
            $out/manifest.json > manifest.json
          mv manifest.json $out/manifest.json
        '';
        hash = "sha256-oF1TBOYaG31n1uU1xEf1yJRJYBJNgxwX02Vi1+wGxJA=";
      };

      chromium = pkgs.ungoogled-chromium.override {
        commandLineArgs = [
          "--ozone-platform=wayland"
          "--load-extension=${ublock}"
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

          "--enable-features=${
            lib.concatStringsSep "," [
              "VerticalTabs"
              "ReducedSystemInfo"
              "RemoveClientHints"
              "SpoofWebGLInfo"
              "AcceleratedVideoEncoder" # VA-API
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
              "adguard-spyware-url"
              "block-lan"
              "curben-phishing"
              "fanboy-social"
              "fanboy-cookiemonster"
              "ublock-cookies-easylist"
              "ITA-0"
            ];
          };

          HttpsOnlyMode = "force_enabled";
          PasswordManagerEnabled = false;
          AutofillCreditCardEnabled = false;
          AutofillAddressEnabled = false;
          HighEfficiencyModeEnabled = true;
          MemorySaverModeSavings = 2; # maximum
          BatterySaverModeAvailability = 1;
          BackgroundModeEnabled = false;
        };

        initialPrefs.vertical_tabs.enabled = true;
      };

      environment.systemPackages = [ chromium ];
      environment.sessionVariables.BROWSER = lib.getExe chromium;
      xdg.mime.defaultApplications = {
        "text/html" = "chromium-browser.desktop";
        "x-scheme-handler/http" = "chromium-browser.desktop";
        "x-scheme-handler/https" = "chromium-browser.desktop";
      };
    };

  aspects.browser.user.preserve.directories = [
    {
      directory = ".config/chromium";
      mode = "0700";
    }
  ];
}
