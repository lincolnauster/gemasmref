{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.stlsc.url = "github:lincolnauster/stlsc.nix";
  inputs.stlsc.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, stlsc }:
    let pkgs = import nixpkgs { system = "x86_64-linux"; };
        cert = stlsc.defaultPackage.x86_64-linux;
    in {
      devShell.x86_64-linux = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ swiProlog ];

        shellHook = ''
          export GEMASM_TLS_CERT=${cert}/tlscert.pem
          export GEMASM_TLS_KEY=${cert}/privkey.pem
        '';
      };
    };
}
