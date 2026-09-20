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

        mistral = {
          name = "Mistral";
          npm = "@ai-sdk/openai-compatible";
          models = {
            "zai-glm-5-3" = {
              name = "GLM-5.3";
              attachment = true;
              tool_call = true;
              reasoning = true;
              temperature = true;
              limit = {
                context = 1000000;
                output = 131072;
              };
              modalities = {
                input = [ "text" ];
                output = [ "text" ];
              };
            };
            "zai-glm-5-2" = {
              name = "GLM-5.2";
              attachment = true;
              tool_call = true;
              reasoning = true;
              temperature = true;
              limit = {
                context = 1000000;
                output = 131072;
              };
              modalities = {
                input = [ "text" ];
                output = [ "text" ];
              };
            };
          };
          options = {
            baseURL = "https://api.mistral.ai/v1";
          };
        };
      };
    };
  };

  xdg.configFile = {
    # GLM-5.2 / GLM-5.3 compatibility plugin — intercepts the Mistral SSE stream
    # to inject missing tool-call IDs and flatten structured content arrays
    # before they hit the Zod schema validator.
    # https://github.com/anomalyco/opencode/issues/43199
    # https://gist.github.com/lloeki/e3c0d15ad1d0964e42efde1f7cf44e07
    "opencode/plugins/mistral-glm-model.ts".text =
      builtins.replaceStrings
        [
          ''id === "mistral-openai"''
          ''const MODEL = "zai-glm-5-2"''
          "Object.hasOwn(provider.models ?? {}, MODEL)"
          "body.model === MODEL"
        ]
        [
          ''id === "mistral"''
          ''const MODELS = ["zai-glm-5-2", "zai-glm-5-3"]''
          "MODELS.some(m => Object.hasOwn(provider.models ?? {}, m))"
          "MODELS.includes(body.model)"
        ]
        (
          builtins.readFile (
            pkgs.fetchurl {
              url = "https://gist.github.com/lloeki/e3c0d15ad1d0964e42efde1f7cf44e07/raw/mistral-glm-model.ts";
              hash = "sha256-ATeoPDk0B7SGue641QUFLVSZYBxp5xjSMbCQ32kGjMA=";
            }
          )
        );

    # Global instructions opencode injects into every session's system prompt.
    "opencode/AGENTS.md".text = ''
      # Global instructions

      - You do not guess. You browse the internet and online docs to check.

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
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  sops.secrets.scaleway_key = {
    sopsFile = "${secretsPath}/secrets/scaleway.sops.yaml";
  };
}
