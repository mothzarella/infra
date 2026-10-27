# text and code open in gram unless a desktop says otherwise
{
  aspects.tar.nixos =
    { lib, ... }:
    {
      xdg.mime.defaultApplications = {
        "text/plain" = lib.mkDefault "app.liten.Gram.desktop";
        "text/markdown" = lib.mkDefault "app.liten.Gram.desktop";
        "text/csv" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-log" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-patch" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-nix" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-python" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-shellscript" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-csrc" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-chdr" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-c++src" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-c++hdr" = lib.mkDefault "app.liten.Gram.desktop";
        "text/rust" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-go" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-lua" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-java" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-kotlin" = lib.mkDefault "app.liten.Gram.desktop";
        "text/x-csharp" = lib.mkDefault "app.liten.Gram.desktop";
        "text/javascript" = lib.mkDefault "app.liten.Gram.desktop";
        "text/css" = lib.mkDefault "app.liten.Gram.desktop";
        "application/x-shellscript" = lib.mkDefault "app.liten.Gram.desktop";
        "application/sql" = lib.mkDefault "app.liten.Gram.desktop";
        "application/json" = lib.mkDefault "app.liten.Gram.desktop";
        "application/toml" = lib.mkDefault "app.liten.Gram.desktop";
        "application/yaml" = lib.mkDefault "app.liten.Gram.desktop";
        "application/xml" = lib.mkDefault "app.liten.Gram.desktop";
      };
    };
}
