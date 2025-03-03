{
  inputs = {
    nix.url = "github:nixos/nix/2.24.10";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { nixpkgs, nix, ... }@inputs:
    let
      auserSSHKey = ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwhhgi3mcPuBvMSoU2L3VbH2siynVoTD3AmJz8z1fmx'';
      rootSSHKey = ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID1lhDqGCDUSwcGwkfNUJeK99zqYIdwjE4v8E0yNKhpp auser@MacBook-Pro-4.local root@auser.local'';
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        inherit system;
        pkgs = import nixpkgs {
          inherit system;
        };
      });
      devTools = { system, pkgs }: [
        pkgs.minio-client
      ];
    in
    {
      devShells = forAllSystems ({ system, pkgs }: {
        default = pkgs.mkShell {
          buildInputs = (devTools { system = system; pkgs = pkgs; });
        };
      });
      nixosConfigurations = {
        hetzner-builder-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            auserSSHKey = auserSSHKey;
            rootSSHKey = rootSSHKey;
          };
          modules = [
            ./systems/hetzner/builder/config.nix
            {
              imports = [ "${nixpkgs}/nixos/modules/profiles/hardened.nix" ];
            }
          ];
        };
        hetzner-dedicated-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            system = "x86_64-linux";
            auserSSHKey = auserSSHKey;
            rootSSHKey = rootSSHKey;
            inputs = inputs;
          };
          modules = [
            ./systems/hetzner/dedicated/config.nix
            ./systems/hetzner/dedicated/dnsmasq.nix
            ./systems/hetzner/dedicated/frp.nix
          ];
        };
        builder-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            auserSSHKey = auserSSHKey;
            rootSSHKey = rootSSHKey;
          };
          modules = [
            ./systems/utm/builder/config.nix
          ];
        };
        builder-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            auserSSHKey = auserSSHKey;
            rootSSHKey = rootSSHKey;
          };
          modules = [
            ./systems/utm/builder/config.nix
          ];
        };
      };
    };
}
