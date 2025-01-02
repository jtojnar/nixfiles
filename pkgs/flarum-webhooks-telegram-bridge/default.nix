{
  lib,
  fetchFromGitHub,
  php,
  unstableGitUpdater,
  writeShellScript,
  common-updater-scripts,
  _experimental-update-script-combinators,
}:

php.buildComposerProject {
  pname = "flarum-webhooks-telegram-bridge";
  version = "0+unstable-2024-07-13";

  src = fetchFromGitHub {
    owner = "ogioncz";
    repo = "flarum-webhooks-telegram-bridge";
    rev = "9705cbd5f1f05b5d8810458d6fa4551786d327f0";
    hash = "sha256-x8JXVD5LFM3mNuz7snUhleCfKeXGEiqoodtDgTVsREc=";
  };

  vendorHash = "sha256-qlPA4rTpdOQ8bnRIb5YfoZreI3iJrMl8WHLkvRaF5Ew=";

  passthru.updateScript =
    let
      update-source-version = lib.getExe' common-updater-scripts "update-source-version";
      updateSource = unstableGitUpdater { };
      resetVersion = writeShellScript "prefix-version" ''
        # Change `0-` version prefix to `0+` since `mkComposerRepository` did not like the former.
        # https://github.com/NixOS/nixpkgs/issues/326835
        version=$(nix-instantiate --eval --json -A flarum-webhooks-telegram-bridge.version | sed 's/"//g; s/^0-/0+/')
        ${update-source-version} flarum-webhooks-telegram-bridge "$version" --ignore-same-hash
      '';
      updateDeps = [
        update-source-version
        "flarum-webhooks-telegram-bridge"
        "--ignore-same-version"
        "--source-key=composerRepository"
      ];
    in
    _experimental-update-script-combinators.sequence [
      updateSource
      resetVersion
      updateDeps
    ];

  meta = {
    description = "Bridge between Flarum Webhooks extension and Telegram";
    homepage = "https://github.com/ogioncz/flarum-webhooks-telegram-bridge";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
