{
  config,
  lib,
  pkgs,
  secretsPath,
  ...
}:

{
  programs.opencode = {
    enable = true;

    tui.theme = lib.mkForce "nord";

    settings = {
      model = "mistral/zai-glm-5-3";

      provider = {
        scaleway = {
          options = {
            apiKey = "{file:${config.sops.secrets.scaleway_key.path}}";
            baseURL = "https://api.scaleway.ai/v1";
          };

          models = {
            qwen36 = {
              name = "qwen3.6-35b-a3b";
            };
          };
        };

        vllm = {
          name = "vLLM";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "http://localhost:8000/v1";  # SSH tunnel port
          };
          models = {
            "Qwen/Qwen3.8-27B" = {
              name = "Qwen3.8-27B";
            };
          };
        };
      };
    };
  };

  xdg.configFile = {
    # Global instructions opencode injects into every session's system prompt.
    "opencode/AGENTS.md".text = ''
      # Global instructions

      - You do not guess. You browse the internet and online docs to check.

      - Your are running inside Code-on-Incus (coi), a sandbox
      with my projects at /workspace, correct file ownership (no more chown),
      Docker and gh available inside, and every workspace change saved back
      to the host. It has no access to my host SSH keys, environment
      variables, or credentials. Of course you should not try to break the
      sandbox. Also, do not download binary blobs from the internet via curl
      or bash. More generally, do not attempt anything unsecure. Doing so
      will trigger the immediate destruction on the sandbox.

      - Never post or reply to comments on GitHub on my behalf. This includes
      PR/issue comments, review comments and their replies, and reviews —
      whether via `gh`, the GitHub REST/GraphQL API, or any MCP/tool. I don't
      want you to publish PR or issue descriptions either. Reading GitHub is
      fine. If a comment/reply genuinely seems needed, draft the text and let
      me post it myself, same for PRs and issues.

      - Never commit code on my behalf. Never push commits on my behalf.

      - When using infrastructure-as-code tools, do not 'apply' on my behalf.
      I want to run these commands myself.

      - Say "I don't know" if you don't know. Ask questions if some
      clarification is needed.

      - Stick to the following principles: readability first. Small functions.
      Single responsibility. Keep changes minimal, implement only what's
      necessary.

      - Try to reuse existing functions if possible. Do not blindly copy/paste
      code sections without thinking about the broader context at the new
      location. Always take some perspective.

      - Do not remove existing comments. Comments are useful for humans. Do
      not hesitate to write additional comments to explain tricky sections.

      - No fallbacks by default. Add them only if explicitly requested or
        strictly required.

      - When implementing a new feature, do not keep legacy codepaths unless
      asked explicitly. Also, don't comment on the fact that the code has
      changed.

      - When writing docs or READMEs, do not write the complete and detailed
      project directory tree, unless it really makes sense for some reason.
      This is often redundant information.
    '';
  };

  systemd.user.services.opencode-serve = {
    Unit = {
      Description = "OpenCode headless server";
      After = [ "network.target" ];
    };

    Service = {
      ExecStart = "/etc/profiles/per-user/thomas/bin/opencode serve --port 4096 --hostname 127.0.0.1";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [ "OPENCODE_SERVER_PASSWORD=dGCPQkzyEcdTlLzqAVfDQS2UdDSzqb0M" ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  sops.secrets.scaleway_key = {
    sopsFile = "${secretsPath}/secrets/scaleway.sops.yaml";
  };
}
