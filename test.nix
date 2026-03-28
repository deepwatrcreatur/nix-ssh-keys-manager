let
  lib = import <nixpkgs/lib>;
  parseSSHConfig = import ./lib/parse-ssh-config.nix { inherit lib; };

  content = ''
    Host server1
      User myuser
      Port 2222
      Hostname 10.10.10.20

    Host gateway
      IdentityFile ~/.ssh/id_rsa
      Hostname 10.10.10.1

    Host *
      Hostname 192.0.2.1
  '';
in
parseSSHConfig content
