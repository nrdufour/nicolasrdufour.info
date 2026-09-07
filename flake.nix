{
  description = "nicolasrdufour.info - Personal landing page for nicolasrdufour.info, built with Hugo";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            hugo # the site generator; its version is pinned by flake.lock, nowhere else
            just # the task runner; `just` alone lists every recipe
            tea # forge.internal PRs and issues (see the create-pr skill)
            forgejo-cli # `fj`: same forge, the other CLI
            nixfmt
            statix
            deadnix
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
