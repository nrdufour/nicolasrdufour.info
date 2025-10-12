{ nixpkgs ? import <nixpkgs> {} }:
with nixpkgs; mkShell {
  packages = [
    hugo
  ];
}
