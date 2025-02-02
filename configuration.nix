# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  stripe-cli = pkgs.stdenv.mkDerivation rec {
    pname = "stripe-cli";
    version = "1.23.9";
    src = pkgs.fetchurl {
      url =
        "https://github.com/stripe/stripe-cli/releases/download/v1.23.9/stripe_1.23.9_linux_x86_64.tar.gz";
      sha256 = "1rvvvfam1a781vy3wgqrrf83i8jvw4xwia3415ly2xgybzdppkzn";
    };

    # Force creation of a directory structure
    unpackPhase = ''
      mkdir stripe-cli
      tar xzf $src -C stripe-cli
      cd stripe-cli
    '';

    # The tarball contains a single binary named 'stripe'
    installPhase = ''
      install -Dm755 stripe $out/bin/stripe
    '';
  };
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.interfaces = {
    wlp15s0 = { wakeOnLan.enable = true; };
    enp14s0 = { wakeOnLan.enable = true; };
  };

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable openrgb
  services.hardware.openrgb.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Set RTC to use local time instead of UTC
  time.hardwareClockInLocalTime = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.molly = {
    isNormalUser = true;
    description = "Szymon Kaszuba-Galka";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs;
      [
        kdePackages.kate
        #  thunderbird
      ];
  };

  # Enable Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;

  # Enable zsh and set it as the default shell
  users.defaultUserShell = pkgs.zsh;

  programs = {
    steam.enable = true;
    firefox.enable = true;
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      ohMyZsh = {
        enable = true;
        plugins = [ "git" "history" ];
        theme = "robbyrussell";
      };
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ glibc libcxx ];
    };
  };

  # ensure xorg uses the nvidia driver
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    nvidia = {
      # enable modesetting for Wayland comaptibility
      modesetting.enable = true;

      # use stable nvidia driver package
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      # enable nvidia settings gui
      nvidiaSettings = true;
      open = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # various utils
    wget
    pciutils
    zsh
    gh
    git
    stripe-cli
    btop
    nvtopPackages.full # previously nvtop
    radeontop
    neofetch
    openrgb-with-all-plugins
    prisma-engines
    openssl
    nixfmt-classic
    direnv
    # bluetooth
    bluez
    bluez-tools
    # programming
    vscode
    nodejs_22
    go
    python3
    obsidian
    # media
    google-chrome
    spotify
    discord-ptb
    slack
    xournalpp
  ];

  # Add Prisma environment variables
  environment.sessionVariables = {
    PRISMA_QUERY_ENGINE_LIBRARY =
      "${pkgs.prisma-engines}/lib/libquery_engine.node";
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
    PRISMA_INTROSPECTION_ENGINE_BINARY =
      "${pkgs.prisma-engines}/bin/introspection-engine";
    PRISMA_FMT_BINARY = "${pkgs.prisma-engines}/bin/prisma-fmt";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
