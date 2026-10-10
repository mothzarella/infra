# runtime checks for the stig aspect: nix build .#checks.x86_64-linux.stig
{ config, inputs, ... }:
{
  flake.checks.x86_64-linux.stig = inputs.nixpkgs.legacyPackages.x86_64-linux.testers.runNixOSTest {
    name = "stig";
    nodes.machine =
      { pkgs, ... }:
      {
        imports = [ config.aspects.stig.nixos ];
        virtualisation.memorySize = 1536;
        networking.nftables.enable = true;
        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
        };
        security.doas.enable = true;
        users.users.alice = {
          isNormalUser = true;
          password = "Correct-Horse-Battery-9";
        };
        environment.systemPackages = [ pkgs.pamtester ];
      };

    testScript = ''
      machine.wait_for_unit("multi-user.target")

      with subtest("audit"):
          machine.wait_for_unit("auditd.service")
          machine.succeed("systemctl is-active audit-rules-nixos.service")
          machine.succeed("grep -w audit=1 /proc/cmdline")
          rules = machine.succeed("auditctl -l")
          assert "loginuid_immutable 1" in machine.succeed("auditctl -s"), "loginuid not immutable"
          assert rules.count("\n") >= 30, "rules missing"
          machine.succeed("touch /etc/doas.conf")
          machine.wait_until_succeeds("ausearch -k identity | grep doas.conf")
          machine.succeed("stat -c '%a %U %G' /var/log/audit | grep '^700 root root'")
          machine.succeed("stat -c '%a %U %G' /var/log/audit/audit.log | grep -E '^(600|400) root root'")

      with subtest("apparmor"):
          machine.succeed("grep apparmor /sys/kernel/security/lsm")
          machine.succeed("[ $(cat /sys/module/apparmor/parameters/enabled) = Y ]")

      with subtest("faillock"):
          # success resets the tally
          machine.succeed("echo Correct-Horse-Battery-9 | pamtester login alice authenticate acct_mgmt")
          for _ in range(3):
              machine.fail("echo wrong | pamtester login alice authenticate")
          print(machine.succeed("faillock --user alice"))
          machine.fail("echo Correct-Horse-Battery-9 | pamtester login alice authenticate")
          machine.succeed("faillock --user alice --reset")
          machine.succeed("echo Correct-Horse-Battery-9 | pamtester login alice authenticate")
          machine.succeed("grep -q pam_faillock /etc/pam.d/doas")

      with subtest("pwquality"):
          machine.fail("printf 'short1A!\\nshort1A!\\n' | pamtester passwd alice chauthtok")
          machine.fail("printf 'alllowercaseletters\\nalllowercaseletters\\n' | pamtester passwd alice chauthtok")
          machine.succeed("printf 'Xk9!mQ2#vL7$pR4zW\\nXk9!mQ2#vL7$pR4zW\\n' | pamtester passwd alice chauthtok")
          machine.succeed("echo 'Xk9!mQ2#vL7$pR4zW' | pamtester login alice authenticate")

      with subtest("login"):
          machine.succeed("grep -q 'Authorized use only' /etc/issue")
          machine.succeed("grep -oP 'pam_limits.so conf=\\K\\S+' /etc/pam.d/login | xargs grep -E 'hard +maxlogins +10'")
          machine.succeed("grep -E '^FAIL_DELAY +4' /etc/login.defs")

      with subtest("sshd"):
          machine.wait_for_unit("sshd.service")
          t = machine.succeed("sshd -T").lower()
          assert "ciphers aes256-ctr,aes192-ctr,aes128-ctr" in t, t
          assert "macs hmac-sha2-512,hmac-sha2-256" in t, t
          assert "loglevel verbose" in t
          assert "clientaliveinterval 600" in t
          assert "clientalivecountmax 1" in t
          machine.succeed("ssh-keygen -q -t ed25519 -N ''' -f /root/k")
          machine.succeed("install -d -m700 -o alice /home/alice/.ssh && install -m600 -o alice /root/k.pub /home/alice/.ssh/authorized_keys")
          out = machine.succeed("ssh -i /root/k -o StrictHostKeyChecking=no alice@localhost 'echo ok' 2>&1")
          assert "Authorized use only" in out and "ok" in out, out

      with subtest("nftables"):
          print(machine.succeed("nft list table inet stig-ratelimit"))
          machine.succeed("systemctl is-active nftables.service")
    '';
  };
}
