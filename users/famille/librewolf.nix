{
  config,
  pkgs,
  nur,
  ...
}:

{
  programs.librewolf = {
    enable = true;

    profiles.default = {
      isDefault = true;

      search = {
        force = true; # Override default search engines

        engines = {
          "qwant" = {
            urls = [
              {
                template = "https://www.qwant.com/?q={searchTerms}";
              }
            ];
            icon = "https://upload.wikimedia.org/wikipedia/commons/2/2b/Qwant-Icone-2022.svg";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = [ "!q" ];
          };
        };

        default = "qwant";
        privateDefault = "qwant";
      };
    };

    languagePacks = [ "fr" ];

    settings = {
      "intl.accept_languages" = "fr,en-US";
      "intl.locale.requested" = "fr,en-US";

      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.dowloads" = true;
      "privacy.clearOnShutdown.cookies" = false;
      "privacy.clearOnShutdown.cache" = false;
      "privacy.clearOnShutdown.offlineApps" = false;
      "services.sync.prefs.sync.privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
      "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
      "privacy.resistFingerprinting" = false;

      "identity.fxaccounts.enabled" = true;

      "browser.tabs.loadInBackground" = true;
      "browser.toolbars.bookmarks.visibility" = "always";

      "signon.rememberSignons" = false;
      "signon.rememberSignons.visibilityToggle" = false;
      "services.sync.prefs.sync.signon.rememberSignons" = false;
      "services.sync.prefs.sync-seen.services.sync.prefs.sync.signon.rememberSignons" = false;

      "browser.translations.enable" = false;
      "extensions.pocket.enabled" = false;
      "browser.tabs.tabmanager.enabled" = false;
      "browser.firefox-view.virtual-list.enabled" = false;
      "browser.urlbar.suggest.recentsearches" = false;
      "browser.urlbar.suggest.history" = false;
      "browser.urlbar.suggest.bookmark" = true;
      "browser.urlbar.suggest.weather" = false;
      "browser.urlbar.suggest.trending" = false;
      "browser.urlbar.suggest.yelp" = false;
      "browser.urlbar.suggest.pocket" = false;
      "browser.urlbar.suggest.addons" = false;
      "browser.urlbar.suggest.mdn" = false;
      "browser.urlbar.suggest.clipboard" = false;

      "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = true;

      # Use native file picker instead of GTK file picker
      "widget.use-xdg-desktop-portal.file-picker" = 1;

      # Activate HTTPS-Only Mode in all windows
      # Forces secure HTTPS connections for all sites
      "dom.security.https_only_mode" = true;
      "dom.security.https_only_mode_ever_enabled" = true;

      # DNS over HTTPS (DoH) with DNS4EU
      # Mode 3 = DoH only, no fallback to traditional DNS
      "network.trr.mode" = 3;
      "network.trr.custom_uri" = "https://noads.joindns4.eu/dns-query";
      "network.trr.uri" = "https://noads.joindns4.eu/dns-query";
      "network.trr.confirmationNS" = "skip";
      # Tailnet names (MagicDNS) are only resolvable via the OS resolver
      "network.trr.excluded-domains" = "ts.net";
      "network.dns.skipTRR-when-parental-control-enabled" = false;

      # Enable HTTP/3 (QUIC) for better performance and security
      "network.http.http3.enabled" = true;

      # Always ask where to download
      "browser.download.useDownloadDir" = false;

      # Trying to make screen sharing, cameras, and microphones work
      "media.webrtc.camera.allow-pipewire" = true;
      "media.webrtc.capture.allow-pipewire" = true;
      "media.gmp-provider.enabled" = true;
      "media.gmp-gmpopenh264.enabled" = true;
      "media.webrtc.hw.h264.enabled" = true;
    };
  };
}
