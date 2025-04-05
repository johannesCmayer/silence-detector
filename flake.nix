{
  description = "Detect when you speak and give rewarding feedback.";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            bash
            sox
            bc
            nix
            mpv
            dzen2
            gawk
            bb

            python3
            python312Packages.pymicro-vad
            python312Packages.pyaudio

            ffmpeg

            hy
            python312Packages.hy
            python312Packages.hyrule
          ];
        };
      });
    };
}
