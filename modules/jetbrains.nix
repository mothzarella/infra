{
  aspects.jetbrains.user =
    { pkgs, ... }:
    {
      packages = [
        pkgs.jetbrains.idea
        pkgs.jetbrains.rider
        pkgs.jetbrains.pycharm
      ];

      preserve.directories = [
        ".config/JetBrains"
        ".local/share/JetBrains"
        ".cache/JetBrains"
        ".java"
        ".jdks"
        ".m2"
        {
          directory = ".junie";
          mode = "0700";
        }
      ];
    };
}
