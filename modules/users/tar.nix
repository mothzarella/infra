{ config, ... }: {
  aspects.tar = {
    includes = with config.aspects; [ xdg ];

    nixos =
      {
        lib,
        pkgs,
        ...
      }:
      {
        environment.sessionVariables.EDITOR = lib.getExe pkgs.neovim;
        environment.sessionVariables.VISUAL = lib.getExe pkgs.neovim;

        preservation.preserveAt."/persistent".users.tar.directories = [
          "Documents"
          "Downloads"
          "Pictures"
          ".config/git"
          {
            directory = ".ssh";
            mode = "0700";
          }
          ".config/claude"
          ".config/nnn"
          ".local/share/zathura"
          ".local/share/zoxide"
          ".local/state/bash"
          ".local/state/nvim"
          ".local/state/wireplumber"
          ".cache/tealdeer"
        ];
      };

    user =
      {
        lib,
        pkgs,
        ...
      }:
      {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPasswordFile = "/persistent/passwd";

        mimeApps =
          lib.genAttrs [ "application/pdf" "application/epub+zip" ] (_: "org.pwmt.zathura-pdf-mupdf.desktop")
          // lib.genAttrs (map (t: "image/${t}") [
            "png"
            "jpeg"
            "gif"
            "webp"
            "bmp"
            "tiff"
            "svg+xml"
            "avif"
            "heif"
            "jxl"
          ]) (_: "imv.desktop")
          // {
            "text/plain" = "nvim.desktop";
            "inode/directory" = "nnn.desktop";
          };

        packages = with pkgs; [
          # GUI
          (zathura.override { plugins = [ zathuraPkgs.zathura_pdf_mupdf ]; }) # pdf only
          imv # images

          # CLI
          curl
          openssh # ssh, scp
          ripgrep # grep
          fd # find
          sd # sed
          ncdu # du
          bottom # top
          jq # json
          nnn # file manager
          gitMinimal
          zoxide # cd (w fzf)
          pv # pipe
          tealdeer # tldr
          entr # file watcher
          wiremix # pavucontrol
          abduco # session detach

          claude-code

          neovim
          vis
        ];

        files.".config/zathura/zathurarc" = pkgs.writeText "zathurarc" ''
          set font "Unifont 12"
          set selection-clipboard clipboard
          set adjust-open width
          set window-title-basename true
          set statusbar-home-tilde true

          set default-bg "#000000"
          set default-fg "#ffffff"
          set statusbar-bg "#000000"
          set statusbar-fg "#ffffff"
          set inputbar-bg "#000000"
          set inputbar-fg "#ffffff"
          set notification-error-bg "#000000"
          set notification-error-fg "#ff5555"
          set completion-highlight-bg "#ffffff"
          set completion-highlight-fg "#000000"
          set index-active-bg "#ffffff"
          set index-active-fg "#000000"

          # dark pages, ctrl+r back to original colors
          set recolor true
          set recolor-lightcolor "#000000"
          set recolor-darkcolor "#ffffff"
          set recolor-keephue true
        '';
      };
  };
}
