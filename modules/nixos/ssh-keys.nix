{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ssh-keys-manager;
  
  # Read all .pub files from the keys directory
  pubKeyFiles = if cfg.keysDirectory != null then
    builtins.attrNames (
      filterAttrs (name: type: 
        type == "regular" && hasSuffix ".pub" name
      ) (builtins.readDir cfg.keysDirectory)
    )
  else [];

  # Read content of each public key file
  pubKeys = map (file: 
    strings.trim (builtins.readFile (cfg.keysDirectory + "/${file}"))
  ) pubKeyFiles;
  
  # Filter keys by username if specified
  userKeys = if cfg.username != null then
    filter (key: 
      any (file: strings.hasInfix cfg.username file) pubKeyFiles
    ) pubKeys
  else pubKeys;

in
{
  options.services.ssh-keys-manager = {
    enable = mkEnableOption "SSH keys manager for authorized_keys";

    keysDirectory = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./ssh-keys";
      description = ''
        Path to directory containing .pub files.
        All .pub files in this directory will be added to authorized_keys.
      '';
    };

    username = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "myuser";
      description = ''
        Username for which to configure authorized_keys.
        If not specified, keys must be manually assigned to users.
      '';
    };

    enableDynamicKeys = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable hybrid authorized_keys approach.
        Allows users to manually add keys to ~/.ssh/authorized_keys_dynamic
        in addition to NixOS-managed keys.
      '';
    };

    extraAuthorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Additional authorized keys to add directly (not from files).
      '';
    };
  };

  config = mkIf cfg.enable {
    # Configure user's authorized keys if username is specified
    users.users = mkIf (cfg.username != null) {
      ${cfg.username} = {
        openssh.authorizedKeys.keys = userKeys ++ cfg.extraAuthorizedKeys;
      };
    };

    # Ensure SSH service is enabled
    services.openssh.enable = mkDefault true;

    # Enable hybrid authorized_keys: NixOS-managed + user-managed dynamic keys
    services.openssh.extraConfig = mkIf cfg.enableDynamicKeys ''
      # Check both NixOS-managed and user-managed keys
      AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys_dynamic
    '';

    # Create mutable authorized_keys_dynamic file for each configured user
    systemd.tmpfiles.rules = mkIf (cfg.enableDynamicKeys && cfg.username != null) [
      "d /home/${cfg.username}/.ssh 0700 ${cfg.username} users - -"
      "f /home/${cfg.username}/.ssh/authorized_keys_dynamic 0600 ${cfg.username} users - -"
    ];
  };
}
