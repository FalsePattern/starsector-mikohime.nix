{ lib
, fetchzip
, libGL
, makeWrapper
, openal
, jdk23
, stdenv
, xorg
, copyDesktopItems
, makeDesktopItem
, writeScript
}:

stdenv.mkDerivation rec {
  pname = "starsector";
  version = "0.97a-RC11";

  srcs = [
    (fetchzip {
      url = "https://f005.backblazeb2.com/file/fractalsoftworks/release/starsector_linux-${version}.zip";
      sha256 = "sha256-KT4n0kBocaljD6dTbpr6xcwy6rBBZTFjov9m+jizDW4=";
      name = pname;
    })
    (fetchzip {
      url = "https://github.com/Yumeris/Mikohime_Repo/releases/download/26.4d/Kitsunebi_23_R26.4f_097a-RC11_linux.zip";
      sha256 = "sha256-dYk4K76oZEDjQRuNxSsAJ4rP3lfF+mJMUkMCJ6OA0dM=";
      name = "mikohime";
      stripRoot = false;
    })
  ];

  sourceRoot = ".";

  nativeBuildInputs = [ copyDesktopItems makeWrapper ];
  buildInputs = [ xorg.libXxf86vm openal libGL ];

  dontBuild = true;

  desktopItems = [
    (makeDesktopItem {
      name = "starsector";
      exec = "starsector";
      icon = "starsector";
      comment = meta.description;
      genericName = "starsector";
      desktopName = "Starsector";
      categories = [ "Game" ];
    })
  ];

  # need to cd into $out in order for classpath to pick up correct jar files
  installPhase = let

    starsector-home = ''''${XDG_DATA_HOME:-\$HOME/.local/share}/starsector'';
  in ''
    runHook preInstall

    pushd ./starsector
    mkdir -p $out/bin $out/share/starsector
    rm -r jre_linux # remove bundled jre7
    rm starfarer.api.zip
    rm starsector.sh
    cp -r ./* $out/share/starsector
    popd
    pushd "./mikohime/0. Files to put into starsector"
    cp -r ./* $out/share/starsector
    popd
    pushd "./mikohime/1. Pick VMParam Size Here/11GB (Recommended for 32GB)"
    cp -r ./* $out/share/starsector
    popd

    chmod +x $out/share/starsector/Kitsunebi.sh

    mkdir -p $out/share/icons/hicolor/64x64/apps
    ln -s $out/share/starsector/mikohime/ui/s_icon64.png \
      $out/share/icons/hicolor/64x64/apps/starsector.png

    wrapProgram $out/share/starsector/Kitsunebi.sh \
      --prefix PATH : ${lib.makeBinPath [ jdk23 xorg.xrandr ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --run "mkdir -p ${starsector-home}/mods" \
      --run "cp -rn $out/share/starsector/mods/* ${starsector-home}/mods/" \
      --chdir "$out/share/starsector"
    ln -s $out/share/starsector/Kitsunebi.sh $out/bin/starsector

    runHook postInstall
  '';

  # it tries to run everything with relative paths, which makes it CWD dependent
  # also point mod, screenshot, and save directory to $XDG_DATA_HOME
  # additionally, add some GC options to improve performance of the game,
  # remove flags "PermSize" and "MaxPermSize" that were removed with Java 8 and
  # pass-through CLI args ($@) to the JVM.
  postPatch = let
    starsector-home = ''''${XDG_DATA_HOME:-\$HOME/.local/share}/starsector'';
    pfx = "-Dcom.fs.starfarer.settings.paths";
    homeify = key: relpath: "${pfx}.${key}=${starsector-home}${relpath}";
  in ''
    pushd "./mikohime/1. Pick VMParam Size Here/11GB (Recommended for 32GB)"
    substituteInPlace Miko_R3.txt \
      --replace-fail "./native/linux" "$out/share/starsector/native/linux" \
      --replace-fail "${pfx}.saves=./saves" "" \
      --replace-fail "${pfx}.screenshots=./screenshots" "" \
      --replace-fail "${pfx}.mods=./mods" "" \
      --replace-fail "${pfx}.logs=." "" \
      --replace-fail "./mikohime" "$out/share/starsector/mikohime"
    popd
    pushd "./mikohime/0. Files to put into starsector"
    substituteInPlace Kitsunebi.sh \
      --replace-fail "./jdk-23+9/bin/java" "${jdk23}/bin/java ${homeify "saves" "/saves"} ${homeify "screenshots" "/screenshots"} ${homeify "mods" "/mods"} ${homeify "logs" ""}"
    popd
  '';

  passthru.updateScript = writeScript "starsector-update-script" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl gnugrep common-updater-scripts
    set -eou pipefail;
    version=$(curl -s https://fractalsoftworks.com/preorder/ | grep -oP "https://f005.backblazeb2.com/file/fractalsoftworks/release/starsector_linux-\K.*?(?=\.zip)" | head -1)
    update-source-version ${pname} "$version" --file=./pkgs/games/starsector/default.nix
  '';

  meta = with lib; {
    description = "Open-world single-player space-combat, roleplaying, exploration, and economic game";
    homepage = "https://fractalsoftworks.com";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    license = licenses.unfree;
    maintainers = with maintainers; [ bbigras rafaelrc ];
  };
}
