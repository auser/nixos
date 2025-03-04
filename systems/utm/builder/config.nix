{ pkgs, auserSSHKey, rootSSHKey, ... }:

{
  # Networking
  networking.hostName = "devbox";
  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  # NixOS partition
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Swap partition
  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
    }
  ];

  documentation.nixos.enable = false;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  nix.settings.trusted-users = [ "auser" "@wheel" ];
  nix.settings.system-features = [ "kvm" "nixos-test" ];

  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
      };
    };
    kernelModules = [ "kvm-amd" "kvm-intel" ];
  };
  virtualisation.libvirtd.enable = true;

  users.users = {
    root.hashedPassword = "!"; # Disable root login
    auser = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "changeme";
      openssh.authorizedKeys.keys = [
        auserSSHKey
        rootSSHKey
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    zip
    unzip
    wget
    curl
    python3
  ];


  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  # VDAgent
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  networking.firewall.allowedTCPPorts = [ 22 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
