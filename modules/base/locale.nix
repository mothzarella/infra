{
  aspects.base.nixos = {
    time.timeZone = "Europe/Rome";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_PAPER = "it_IT.UTF-8";
      LC_MEASUREMENT = "it_IT.UTF-8";
    };
  };
}
