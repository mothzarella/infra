{
  aspects.tar.user.preserve.directories = [
    "Projects"
    {
      directory = ".ssh";
      mode = "0700";
    }
    {
      directory = ".config/claude";
      mode = "0700";
    }
    ".config/gram"
    ".local/share/gram"
    ".config/nnn"
    ".local/share/zoxide"
    ".local/state/nvim"
    ".cache/tealdeer"
  ];
}
