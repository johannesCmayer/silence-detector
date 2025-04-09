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

      packages = forEachSupportedSystem ({ pkgs }: rec {
        vocal-reward = derivation {
          name = "vocal-reward";
          system = "x86_64-linux";
          main = ./main.hy;
          PYTHONPATH = "${pkgs.python312Packages.pymicro-vad}/lib/python3.12/site-packages:${pkgs.python312Packages.pyaudio}/lib/python3.12/site-packages";
          PATH = "${pkgs.dzen2}/bin:${pkgs.ffmpeg}/bin";
          nice_beep = ./nice_beep.mp3;
          hyExecutable = "${pkgs.hy}/bin/hy";
          builder = "${pkgs.hy}/bin/hy";
          args = [ ./build.hy ];
        };
        default = vocal-reward;
      });

      nixosModules.default = { config, lib, pkgs, ... }:
        # TODO
        # - Figure out how to test the current configuration quickly (without
        #   needing to create a git commit).
        #   - Maybe buy using a the path type (use files in director instead of
        #     specific git commit, and don't lock flake.lock)
        # - Implement the actual vocal-reward service
        #   - Create a package (or maybe app is better?)
        #   - Create correct service configuration
        #     - How to have a service use the package bin (or run app)?
        let
          inherit (lib) mkIf mkEnableOption;
          cfg = config.services.vocal-reward;
        in
        {
          options.services.vocal-reward.enable = mkEnableOption
            "the vocal-reward user daemon";

          config = mkIf cfg.enable {
            systemd.user.services.vocal-reward = {
              description = "Run the vocal-reward daemon.";
              serviceConfig = {
                ExecStart = "${self.packages."x86_64-linux".vocal-reward}/bin/vocal-reward";
                Restart = "always";
                RestartSec = "1s";
                RestartSteps = 5;
                RestartMaxDelaySec = "60s";
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
