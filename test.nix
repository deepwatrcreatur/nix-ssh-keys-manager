let
  lib = import <nixpkgs/lib>;
  content = ''
    Host server1
      User myuser
      Port 2222
      Hostname 10.10.10.20

    Host gateway
      IdentityFile ~/.ssh/id_rsa
      Hostname 10.10.10.1
  '';
  lines = lib.splitString "\n" content;
  cleanLines = map (line: lib.strings.trim line) (lib.filter (line: 
    !(lib.hasPrefix "#" (lib.strings.trim line)) && (lib.strings.trim line) != ""
  ) lines);

  result = lib.foldl (state: line:
    if lib.hasPrefix "Host " line && line != "Host *" then
      { inherit (state) map; currentHost = lib.removePrefix "Host " line; }
    else if state.currentHost != null && (lib.hasPrefix "Hostname " line || lib.hasPrefix "HostName " line) then
      let
        ip = if lib.hasPrefix "Hostname " line then lib.removePrefix "Hostname " line else lib.removePrefix "HostName " line;
      in
      { map = state.map // { "${state.currentHost}" = ip; }; currentHost = null; }
    else
      state
  ) { map = {}; currentHost = null; } cleanLines;
in result.map