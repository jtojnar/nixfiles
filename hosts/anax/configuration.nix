#
# vpsfree nixos config (openvz)
#

{ config, pkgs, lib, ... }:
let
	mkVirtualHost = { path ? null, config ? "", acme ? null, redirect ? null }:
	(if lib.isString acme then {
		useACMEHost = acme;
		forceSSL = true;
	} else {}) // (if lib.isBool acme then {
		enableACME = acme;
		forceSSL = true;
	} else {}) // (if redirect != null then {
		globalRedirect = redirect;
	} else {}) // (if path != null then {
		root = "/var/www/" + path;
	} else {}) // {
		extraConfig = config;
	};
	mkPhpPool = { user, debug ? false }: {
		listen = "/var/run/phpfpm/${user}.sock";
		extraConfig = ''
			listen.owner = nginx
			listen.group = root
			user = ${user}
			pm = dynamic
			pm.max_children = 5
			pm.start_servers = 2
			pm.min_spare_servers = 1
			pm.max_spare_servers = 3
			${lib.optionalString debug ''
				; log worker's stdout, but this has a performance hit
				catch_workers_output = yes
			''}
		'';
	};
	keys = import ../../keys.nix;
	enablePHP = sockName: ''
		fastcgi_pass unix:/var/run/phpfpm/${sockName}.sock;
		include ${config.services.nginx.package}/conf/fastcgi.conf;
		fastcgi_param PATH_INFO $fastcgi_path_info;
		fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
	'';
	nixos1703 = import <nixos-1703> {};
	unstable = import <unstable> {};
in {
	imports = [
		<unstable/nixos/modules/services/web-servers/nginx/default.nix>
		<nixpkgs/nixos/modules/profiles/minimal.nix>
		<nixpkgs/nixos/modules/virtualisation/container-config.nix>
		<nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
	];

	disabledModules = [
		"services/web-servers/nginx/default.nix"
	];

	networking = {
		hostName = "anax";
		useHostResolvConf = true;
	};

	i18n = {
		defaultLocale = "en_GB.UTF-8";
	};

	time.timeZone = "Europe/Prague";

	programs = {
		fish.enable = true;
		man.enable = true;
	};

	environment.systemPackages = with pkgs; [
		file
		gitAndTools.diff-so-fancy
		gitAndTools.gitFull
		moreutils # isutf8
		ncdu
		ripgrep
		tldr
	];

	services = rec {
		openssh = {
			enable = true;
			permitRootLogin = "no";
			passwordAuthentication = false;
			sftpFlags = [ "-u 0007" ];
			# extraConfig = ''
			# 	Match Group sftp-only
			# 		AllowTCPForwarding no
			# 		X11Forwarding no
			# 		ForceCommand internal-sftp
			# '';
		};

		nginx = {
			enable = true;
			package = unstable.nginx.override {
				openssl = unstable.openssl_1_1;
			};
			sslProtocols = "TLSv1.3 TLSv1.2";
			virtualHosts = {
				# krk-litvinov.cz
				"agenda.krk-litvinov.cz" = mkVirtualHost {
					# acme = "krk-litvinov.cz";
					acme = true;
					path = "krk-litvinov.cz/agenda";
				};
				"bloudeni.krk-litvinov.cz" = mkVirtualHost {
					# acme = "krk-litvinov.cz";
					path = "krk-litvinov.cz/bloudeni";
				};
				"entries.krk-litvinov.cz" = mkVirtualHost {
					acme = true;
					# acme = "krk-litvinov.cz";
					path = "krk-litvinov.cz/entries/www";
					config = ''
						index index.php;

						location / {
							try_files $uri $uri/ /index.php;
						}

						sendfile on;
						send_timeout 1024s;

						location ~ \.php {
							fastcgi_split_path_info ^(.+?\.php)(/.*)$;
							${enablePHP "entries"}
							try_files $uri =404;
						}

						location = /robots.txt { access_log off; log_not_found off; }
						location = /favicon.ico { access_log off; log_not_found off; }
					'';
				};
				"lob-2019.krk-litvinov.cz" = mkVirtualHost {
					# acme = "krk-litvinov.cz";
					acme = true;
					path = "krk-litvinov.cz/lob-2019";
				};
				"rogaining-2019.krk-litvinov.cz" = mkVirtualHost {
					# acme = "krk-litvinov.cz";
					acme = true;
					path = "krk-litvinov.cz/rogaining-2019";
					config = ''
						index index.php;

						location = /favicon.ico {
							log_not_found off;
							access_log off;
						}

						location = /robots.txt {
							allow all;
							log_not_found off;
							access_log off;
						}

						location / {
							# This is cool because no php is touched for static content.
							# include the "?$args" part so non-default permalinks doesn't break when using query string
							try_files $uri $uri/ /index.php?$args;
						}

						location ~ \.php$ {
							#NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
							fastcgi_intercept_errors on;
							fastcgi_read_timeout 500;
							${enablePHP "rogaining-2019"}
						}

						location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
							expires max;
							log_not_found off;
						}
					'';
				};

				"entries.rogaining-2019.krk-litvinov.cz" = mkVirtualHost {
					# acme = "krk-litvinov.cz";
					acme = true;
					path = "krk-litvinov.cz/rogaining-2019/entries/www";
					config = ''
						index index.php;

						location / {
							try_files $uri $uri/ /index.php;
						}

						sendfile on;
						send_timeout 1024s;

						location ~ \.php {
							fastcgi_split_path_info ^(.+?\.php)(/.*)$;
							${enablePHP "entries-2019"}
							try_files $uri =404;
						}

						location = /robots.txt { access_log off; log_not_found off; }
						location = /favicon.ico { access_log off; log_not_found off; }
					'';
				};
			};

		};

		phpfpm = rec {
			# phpPackage = pkgs.php56;
			# phpPackage = pkgs.php.overrideAttrs (super: {buildInputs = super.buildInputs ++ [ pkgs.zlib ];});
			phpOptions = ''
				display_startup_errors = On
				display_errors = On
				log_errors = On
				upload_max_filesize = 20M
				memory_limit = 256M
				default_socket_timeout = 500
				max_execution_time = 500
				request_terminate_timeout = 500
				post_max_size = 20M
				error_reporting = E_ALL | E_STRICT
				date.timezone = "Europe/Prague"
			'';
			pools = {
				entries = mkPhpPool {
					user = "entries";
					debug = true;
				};
				rogaining-2019 = mkPhpPool {
					user = "rogaining-2019";
					debug = true;
				};
				entries-2019 = mkPhpPool {
					user = "entries-2019";
					debug = true;
				};
			};
		};

		mysql = {
			enable = true;
			# ensureDatabases = [ "cpforum" "fcp" "entries" "mechmice" "ostrov-tucnaku" ];
			# ensureUsers = [
			# 	{ name = "cpforum"; ensurePermissions = { "cpforum.*" = "ALL PRIVILEGES"; }; }
			# 	{ name = "fcp"; ensurePermissions = { "fcp.*" = "ALL PRIVILEGES"; }; }
			# 	{ name = "mechmice"; ensurePermissions = { "mechmice.*" = "ALL PRIVILEGES"; }; }
			# 	{ name = "entries"; ensurePermissions = { "entries.*" = "ALL PRIVILEGES"; }; }
			# 	{ name = "tojnar"; ensurePermissions = { "entries.*" = "ALL PRIVILEGES"; }; }
			# 	{ name = "ostrov-tucnaku"; ensurePermissions = { "ostrov-tucnaku.*" = "ALL PRIVILEGES"; }; }
			# ];
			package = unstable.mariadb;
		};
	};


	security.acme.certs = let
		mkCert = { user, domains }: {
			user = user;
			group = user;
			allowKeysForGroup = true;
			webroot = "/var/lib/acme/acme-challenge";
			extraDomains = builtins.listToAttrs (map (d: {name = d; value = null;}) domains);
			postRun = ''
				systemctl reload nginx
			'';
		};
	in {
		# "krk-litvinov.cz" = mkCert {
		# 	user = "";
		# 	domains = [ "bloudeni.krk-litvinov.cz" "entries.krk-litvinov.cz" ];
		# };
	};

	users = {
		users = {
			jtojnar = {
				isNormalUser = true;
				uid = 1000;
				extraGroups = [ "wheel" "entries" "rogaining-2019" "entries-2019" ];
				openssh.authorizedKeys.keys = keys.jtojnar;
				hashedPassword = "$6$yqXBTritxLsTNhy.$baY8JEagVyeBmpV6WCLY7nH4YH6YAjWiBPAvgF0zcVjYr7yagBmpZtmX/EFMedgxbCnU7l97SdG7EV6yfT.In/";
			};

			tojnar = {
				uid = 1001;
				isNormalUser = true;
				extraGroups = [ "entries" "krk" "entries-2019" ];
				openssh.authorizedKeys.keys = keys.otec;
			};

			nginx = {
				extraGroups = [ "entries" "krk" "rogaining-2019" "entries-2019" ];
			};

			entries = { uid = 504; group = "entries"; isSystemUser = true; };
			krk = { uid = 505; group = "krk"; isSystemUser = true; };
			rogaining-2019 = { uid = 507; group = "rogaining-2019"; isSystemUser = true; };
			entries-2019 = { uid = 508; group = "entries-2019"; isSystemUser = true; };
		};

		groups = {
			entries = { gid = 504; };
			krk = { gid = 505; };
			rogaining-2019 = { gid = 507; };
			entries-2019 = { gid = 508; };
		};

		defaultUserShell = pkgs.fish;
		mutableUsers = false;
	};

	nix = {
		useSandbox = true;

		# filterSyscalls = false;
		extraOptions = ''
			filter-syscalls = 0
		'';

		nixPath = [
			"nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-17.09.tar.gz"
			"unstable=https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz"
			"nixos-config=/etc/nixos/configuration.nix"
		];

		# OpenVZ kernel does not support seccomp, required by Nix ≥ 1.11.10
		package = pkgs.nixUnstable;
	};

	nixpkgs.config.packageOverrides = super:
		let
			systemdGperfCompat = super.systemd.override { gperf = super.gperf_3_0; };
		in {
			systemd = systemdGperfCompat.overrideAttrs (oldAttrs: rec {
				version = "232";
				name = "systemd-${version}";
				src = pkgs.fetchFromGitHub {
					owner = "nixos";
					repo = "systemd";
					rev = "66e778e851440fde7f20cff0c24d23538144be8d";
					sha256 = "1valz8v2q4cj0ipz2b6mh5p0rjxpy3m88gg9xa2rcc4gcmscndzk";
				};
			});
		};

	system.stateVersion = "17.03";

	# HIC SUNT LEONES

	fileSystems = [ ];

	system.build.tarball = import <nixpkgs/nixos/lib/make-system-tarball.nix> {
		inherit (pkgs) stdenv perl xz pathsFromGraph;

		contents = [];
		storeContents = [
			{
				object = config.system.build.toplevel + "/init";
				symlink = "/init";
			}
			{
				object = config.system.build.toplevel + "/init";
				symlink = "/bin/init";
			}
			{
				object = config.system.build.toplevel;
				symlink = "/run/current-system";
			}
			# this is needed as openvz uses /bin/sh for running scripts before container starts
			{
				object = config.environment.binsh;
				symlink = "/bin/sh";
			}
		];
		extraCommands = "mkdir -p etc proc sys dev/shm dev/pts run";
	};

	boot.isContainer = true;
	boot.loader.grub.enable = false;
	boot.postBootCommands =
		''
		# After booting, register the contents of the Nix store in the Nix database.
		if [ -f /nix-path-registration ]; then
			${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration {{{METANIX}}}{{{METANIX}}}
			rm /nix-path-registration
		fi

		# nixos-rebuild also requires a "system" profile
		${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

		# we may supply this from host, default /etc/resolv.conf copying in stage-2 works only when /run is mounted from host
		if [ -e /resolv.conf ]; then
			cat /resolv.conf | resolvconf -m 1000 -a host
		fi
		'';

	boot.specialFileSystems."/run/keys".fsType = lib.mkForce "tmpfs";

	# need to remove capabilities added by default by nixos/modules/tasks/network-interfaces.nix
	security.wrappers = {
		ping.source = "${pkgs.iputils.out}/bin/ping";
	};

	# Install new init script(s), takes care of switching symlinks when e.g. nixos-rebuild switch(ing)
	system.activationScripts.installInitScript = ''
		ln -fs $systemConfig/init /init
		ln -fs $systemConfig/init /bin/init
	'';

	systemd.services."getty@".enable = false;
	systemd.services.systemd-sysctl.enable = false;

	systemd.services.networking-setup = {
		description = "Load network configuration provided by host";

		before = [ "network.target" ];
		wantedBy = [ "network.target" ];
		after = [ "network-pre.target" ];
		path = [ pkgs.iproute ];

		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = true;
			ExecStart = "${pkgs.bash}/bin/bash /ifcfg.start";
			ExecStop = "${pkgs.bash}/bin/bash /ifcfg.stop";
		};
	};

	systemd.services.systemd-journald.serviceConfig.SystemCallFilter = "";
	systemd.services.systemd-journald.serviceConfig.MemoryDenyWriteExecute = false;
	systemd.services.systemd-logind.serviceConfig.SystemCallFilter = "";
	systemd.services.systemd-logind.serviceConfig.MemoryDenyWriteExecute = false;
}
