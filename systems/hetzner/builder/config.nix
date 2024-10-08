{ pkgs, adrianSSHKey, rootSSHKey, ... }:

/*
  # Create a new MBR partition table
  parted /dev/sda --script mklabel msdos

  # Create a 512MB boot partition with FAT32
  parted /dev/sda --script mkpart primary fat32 1MiB 513MiB
  parted /dev/sda --script set 1 boot on
  mkfs.vfat -n boot /dev/sda1

  # Create a swap partition of 8GB
  parted /dev/sda --script mkpart primary linux-swap 513MiB 8577MiB
  mkswap -L swap /dev/sda2

  # Create a root partition using the rest of the disk with ext4
  parted /dev/sda --script mkpart primary ext4 8577MiB 100%
  mkfs.ext4 -L nixos /dev/sda3
*/

{
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  environment.systemPackages = [
    pkgs.vim
    pkgs.git
    pkgs.zip
    pkgs.unzip
    pkgs.wget
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
    }
  ];

  documentation.nixos.enable = false;
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "us";
  nix.settings.trusted-users = [ "adrian" "@wheel" ];
  nix.settings.system-features = [ "kvm" "nixos-test" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/disk/by-label/nixos";
  networking.networkmanager.enable = true;

  users.users = {
    root.hashedPassword = "!"; # Disable root login
    adrian = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        adrianSSHKey
        rootSSHKey
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
