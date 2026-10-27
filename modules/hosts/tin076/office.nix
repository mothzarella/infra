{
  aspects.tin076 = {
    user =
      { pkgs, ... }:
      {
        packages = [
          pkgs.teams-for-linux
          pkgs.euro-office-desktopeditors
        ];

        files = {
          ".local/share/fonts/corefonts" = "${pkgs.corefonts}/share/fonts/truetype";
          ".local/share/fonts/vista-fonts" = "${pkgs.vista-fonts}/share/fonts/truetype";
        };

        preserve.directories = [
          "Documents"
          ".config/teams-for-linux"
          ".config/euro-office"
          ".local/share/euro-office"
        ];
      };

    nixos =
      { pkgs, ... }:
      {
        fonts.packages = [
          pkgs.corefonts
          pkgs.vista-fonts
        ];
      };
  };
}
