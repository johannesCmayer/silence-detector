{
  description = "Detect when you speak and give rewarding feedback.";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            dzen2
            ffmpeg

            python3
            python312Packages.pymicro-vad
            python312Packages.pyaudio

            hy
            python312Packages.hy
            python312Packages.hyrule
          ];
        };
      });

      packages = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.dzen2;
      });

      nixosModules.default = { config, lib, pkgs, ... }:
        # TODO
        # - Figure out how to test the current configuration quickly
        # - Somehow have the ExecStart be the program in this repo
        let
          inherit (lib) mkIf mkEnableOption;
          cfg = config.services.vocal-reward;
        in
        {
          options.services.vocal-reward.enable = mkEnableOption
            "the vocal-reward user daemon";

          config = {
            systemd.user.services.vocal-reward = {
              enable = config.services.vocal-reward.enable;
              description = "Update Locate Database";
              serviceConfig = {
                ExecStart = "echo";
              };
            };
            # systemd.user.services.vocal-reward = {
            #   description = "Service to give reward for speaking.";
            #   path = [ pkgs.libnotify ];
            #   script = ''
            #     notify-send "hello from systemd"
            #   '';
            # };
          };
        };
    };
}

