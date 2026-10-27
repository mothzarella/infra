{
  aspects.tin076 = {
    user =
      { pkgs, ... }:
      {
        # NuGet only looks for plugins here, not in $PATH
        files.".nuget/plugins/netcore/CredentialProvider.Microsoft" =
          "${pkgs.azure-artifacts-credprovider}/lib/azure-artifacts-credprovider";

        preserve.directories = [
          ".nuget" # NuGet.Config with the feeds
          {
            directory = ".local/share/.IdentityService"; # MSAL token cache
            mode = "0700";
          }
          {
            directory = ".local/share/MicrosoftCredentialProvider"; # session token cache
            mode = "0700";
          }
        ];
        preserve.files = [
          {
            file = ".npmrc"; # Azure DevOps token
            how = "symlink";
            createLinkTarget = true;
            mode = "0600";
          }
        ];
      };

    nixos.environment.sessionVariables.NUGET_CREDENTIALPROVIDER_MSAL_FILECACHE_ENABLED = "true";
  };
}
