# Anduril NixOS STIG V1R2 (https://www.stigviewer.com/stigs/anduril_nixos)
#
# covered elsewhere: firewall (078), UMASK 077 (181), kptr_restrict/ASLR/syncookies (anssi),
# require-sigs (154), allowed-users @wheel (152), mutableUsers (138), LUKS (144), no autologin (172),
# doas without persist (155/156), idle lock 5 min (086, gnome/mango), vlock in busybox (087),
# no telnet/ftp/tftp applets (131, minimal)
#
# deviations:
# - 081 faillock unlocks after 15 min instead of never
# - 105/106 audit disk full/error -> syslog instead of halt
# - 130/175 yescrypt instead of SHA512
# - 132/133/174 no password aging: users are immutable
# - 137 root ssh with key only (nixos-rebuild --target-host root@)
# - 146/147 wifi and bluetooth stay on (laptops)
# - 149/150/151 ntpd-rs with NTS instead of timesyncd with USNO servers
# - 153 no AIDE: the store is read-only and signed, / is wiped on boot
# not applicable: 079 temporary accounts, 107/108/109 remote log server, 124/136/177/178/179 DoD PKI,
# 139 usbguard, 168 FIPS kernel
{
  aspects.stig.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      faillock = "${config.security.pam.package}/lib/security/pam_faillock.so";
      pwquality = "${pkgs.libpwquality.lib}/lib/security/pam_pwquality.so";
      banner = ''
        Authorized use only. Activity on this system is monitored and logged;
        by continuing you consent to this monitoring.
      '';
      auditRules = arch: [
        # 091, 148
        "-a always,exit -F arch=${arch} -S execve -C uid!=euid -F euid=0 -k execpriv"
        "-a always,exit -F arch=${arch} -S execve -C gid!=egid -F egid=0 -k execpriv"
        # 094
        "-a always,exit -F arch=${arch} -S mount -F auid>=1000 -F auid!=unset -k privileged-mount"
        # 095
        "-a always,exit -F arch=${arch} -S rename,unlink,rmdir,renameat,unlinkat -F auid>=1000 -F auid!=unset -k delete"
        # 096
        "-a always,exit -F arch=${arch} -S init_module,finit_module,delete_module -F auid>=1000 -F auid!=unset -k module_chng"
        # 098
        "-a always,exit -F arch=${arch} -S open,creat,truncate,ftruncate,openat,open_by_handle_at -F exit=-EACCES -F auid>=1000 -F auid!=unset -k access"
        "-a always,exit -F arch=${arch} -S open,creat,truncate,ftruncate,openat,open_by_handle_at -F exit=-EPERM -F auid>=1000 -F auid!=unset -k access"
        # 099, 100
        "-a always,exit -F arch=${arch} -S chown,fchown,lchown,fchownat -F auid>=1000 -F auid!=unset -k perm_mod"
        "-a always,exit -F arch=${arch} -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=unset -k perm_mod"
        # 163
        "-a always,exit -F arch=${arch} -S setxattr,fsetxattr,lsetxattr,removexattr,fremovexattr,lremovexattr -F auid>=1000 -F auid!=unset -k perm_mod"
        "-a always,exit -F arch=${arch} -S setxattr,fsetxattr,lsetxattr,removexattr,fremovexattr,lremovexattr -F auid=0 -k perm_mod"
      ];
    in
    {
      # 081, 171, 126-129, 134, 145, 169, 170: every service with password auth
      options.security.pam.services = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { config, ... }:
            {
              config = lib.mkIf (config.useDefaultRules && config.unixAuth) {
                failDelay = {
                  enable = true;
                  delay = 4000000;
                };
                logFailures = true; # auth faillock, ahead of every password module
                rules = {
                  auth.faillock.settings.preauth = true;
                  auth.faillock-authfail = {
                    order = config.rules.auth.unix.order + 10;
                    control = "[default=die]";
                    modulePath = faillock;
                    settings.authfail = true;
                  };
                  account.faillock = {
                    order = config.rules.account.unix.order + 10;
                    control = "required"; # resets the tally on success
                    modulePath = faillock;
                  };
                  password.pwquality = {
                    order = config.rules.password.unix.order - 10;
                    control = "requisite";
                    modulePath = pwquality;
                  };
                };
              };
            }
          )
        );
      };

      config = {
        security = {
          auditd = {
            enable = true; # 080, 090
            settings = {
              log_group = "root"; # 110
              space_left = "25%"; # 101, 103
              space_left_action = "syslog";
              admin_space_left = "10%"; # 102, 104
              admin_space_left_action = "syslog";
              disk_full_action = "syslog"; # 105
              disk_error_action = "syslog"; # 106
            };
          };

          audit = {
            enable = true; # 080, also sets audit=1 (092)
            backlogLimit = 8192; # 093
            rules = [
              "--loginuid-immutable" # 119
            ]
            ++ auditRules "b32"
            ++ auditRules "b64"
            ++ [
              # store paths: audit doesn't follow the /run/current-system symlinks
              "-a always,exit -F path=${pkgs.shadow}/bin/usermod -F perm=x -F auid>=1000 -F auid!=unset -k privileged-usermod" # 164
              "-a always,exit -F path=${pkgs.shadow}/bin/chage -F perm=x -F auid>=1000 -F auid!=unset -k privileged-chage" # 165
              "-w /var/lib/lastlog -p wa -k logins" # 166, lastlog2
            ]
            # 167
            ++ map (f: "-w ${f} -p wa -k identity") [
              "/etc/passwd"
              "/etc/shadow"
              "/etc/group"
              "/etc/gshadow"
              "/etc/security/opasswd"
              "/etc/doas.conf"
            ]
            # 097
            ++ lib.optionals config.services.cron.enable [
              "-w /var/cron/tabs/ -p wa -k services"
              "-w /var/cron/cron.allow -p wa -k services"
              "-w /var/cron/cron.deny -p wa -k services"
            ];
          };

          apparmor.enable = true; # 173

          loginDefs.settings.FAIL_DELAY = 4; # 171

          # 085
          pam.loginLimits = [
            {
              domain = "*";
              item = "maxlogins";
              type = "hard";
              value = "10";
            }
          ];
        };

        environment.etc = {
          "security/faillock.conf".text = ''
            deny = 3
            fail_interval = 900
            unlock_time = 900
            audit
            silent
          '';
          "security/pwquality.conf".text = ''
            minlen = 15
            dcredit = -1
            ucredit = -1
            lcredit = -1
            ocredit = -1
            difok = 8
            dictcheck = 1
            enforce_for_root
          '';
        };

        services = {
          # 082, 083, 084
          getty.helpLine = banner;
          displayManager.gdm.banner = banner;

          openssh.settings = {
            Banner = "${pkgs.writeText "banner" banner}";
            LogLevel = "VERBOSE"; # 088
            Ciphers = [
              "aes256-ctr"
              "aes192-ctr"
              "aes128-ctr"
            ]; # 089
            Macs = [
              "hmac-sha2-512"
              "hmac-sha2-256"
            ]; # 157
            ClientAliveInterval = 600; # 142
            ClientAliveCountMax = 1; # 143
            UsePAM = true; # 176
          };
        };

        # 158: per-source cap on new tcp connections, ahead of the firewall's accepts
        networking.nftables.tables.stig-ratelimit = lib.mkIf config.networking.nftables.enable {
          family = "inet";
          content = ''
            set conn4 {
              type ipv4_addr
              flags dynamic
              timeout 1m
            }
            set conn6 {
              type ipv6_addr
              flags dynamic
              timeout 1m
            }
            chain input {
              type filter hook input priority filter - 1; policy accept;
              tcp flags & (fin | syn | rst | ack) == syn ct state new add @conn4 { ip saddr limit rate over 1000/minute } drop
              tcp flags & (fin | syn | rst | ack) == syn ct state new add @conn6 { ip6 saddr limit rate over 1000/minute } drop
            }
          '';
        };
      };
    };
}
