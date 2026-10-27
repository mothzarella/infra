# zathura for pdf and epub, imv for images
{
  aspects.silent = {
    nixos.xdg.mime.defaultApplications = {
      "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "application/epub+zip" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "image/*" = "imv.desktop"; # not imv-dir
    };

    user =
      { pkgs, osConfig, ... }:
      let
        inherit (osConfig.silent.theme) c;
      in
      {
        preserve.directories = [ ".local/share/zathura" ];

        files.".config/zathura/zathurarc" = pkgs.writeText "zathurarc" ''
          set font "Unifont 12"
          set selection-clipboard clipboard
          set adjust-open width
          set window-title-basename true
          set statusbar-home-tilde true

          set default-bg "#${c.bg}"
          set default-fg "#${c.fg}"
          set statusbar-bg "#${c.inactiveBg}"
          set statusbar-fg "#${c.fg}"
          set inputbar-bg "#${c.bg}"
          set inputbar-fg "#${c.fg}"
          set notification-error-bg "#${c.bg}"
          set notification-error-fg "#${c.error}"
          set completion-highlight-bg "#${c.keyword}"
          set completion-highlight-fg "#${c.bg}"
          set index-active-bg "#${c.keyword}"
          set index-active-fg "#${c.bg}"

          set recolor true
          set recolor-lightcolor "#${c.bg}"
          set recolor-darkcolor "#${c.fg}"
          set recolor-keephue true
        '';

        packages = [
          (pkgs.zathura.override { plugins = [ pkgs.zathuraPkgs.zathura_pdf_mupdf ]; }) # pdf only
          pkgs.imv
        ];
      };
  };
}
