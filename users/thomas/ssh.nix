{
  config,
  secretsPath,
  ...
}:

let
  ceaSopsFile = "${secretsPath}/secrets/cea.sops.yaml";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include the sops-rendered CEA hosts config
    includes = [
      config.sops.templates."ssh-cea-config".path
    ];

    matchBlocks = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
        # Only offer the keys below, never what happens to sit in the agent
        identitiesOnly = true;
        # Tried in order: YubiKey first, software key as fallback for
        # hosts that don't have the hardware key in authorized_keys yet
        identityFile = [
          "~/.ssh/id_ed25519_sk"
          "~/.ssh/id_ed25519"
        ];
      };

      # Allows to securely use local SSH agent to authenticate on the remote machine.
      # It has the same effect as adding cli option `ssh -A user@host`
      "local" = {
        host = "192.168.*";
        user = "thomas";
        forwardAgent = true;
      };

      "g5k" = {
        host = "g5k";
        user = "tbouvier";
        hostname = "access.grid5000.fr";
        forwardAgent = false;
      };

      "*.g5k" = {
        host = "*.g5k";
        user = "tbouvier";
        proxyCommand = "ssh g5k -W \"$(basename %h .g5k):%p\"";
        forwardAgent = false;
      };

      "access.g5k" = {
        host = "!access.grid5000.fr *.grid5000.fr";
        proxyCommand = "ssh -A tbouvier@194.254.60.33 -W \"$(basename %h):%p\"";
        user = "tbouvier";
        forwardAgent = true;
      };

      "odeai-server" = {
        hostname = "odeai-server.ddns.net";
        user = "thomas";
        port = 6422;
      };
    };
  };

  # CEA secrets from cea.sops.yaml
  sops.secrets."cea/user" = {
    sopsFile = ceaSopsFile;
  };
  sops.secrets."cea/challenger_hostname" = {
    sopsFile = ceaSopsFile;
  };
  sops.secrets."cea/mandelbrot_smp_hostname" = {
    sopsFile = ceaSopsFile;
  };
  sops.secrets."cea/mandelbrot_rtx_hostname" = {
    sopsFile = ceaSopsFile;
  };

  # SSH config snippet with secrets injected at activation time
  sops.templates."ssh-cea-config" = {
    content = ''
      Host challenger
          HostName ${config.sops.placeholder."cea/challenger_hostname"}
          User ${config.sops.placeholder."cea/user"}

      Host mandelbrot-smp
          HostName ${config.sops.placeholder."cea/mandelbrot_smp_hostname"}
          User ${config.sops.placeholder."cea/user"}
          ProxyJump challenger

      Host mandelbrot-rtx
          HostName ${config.sops.placeholder."cea/mandelbrot_rtx_hostname"}
          User ${config.sops.placeholder."cea/user"}
          ProxyJump mandelbrot-smp
    '';
  };
}
