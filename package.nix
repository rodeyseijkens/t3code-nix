{
  lib,
  pkgs,
  pname ? "t3code",
  version,
  hash,
}: let
  src = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    inherit hash;
  };
  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
  };
in
  pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    pkgs = pkgs;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/t3code.desktop $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${appimageContents}/usr/share/icons $out/share

      if [ "${pname}" != "t3code" ]; then
        substituteInPlace $out/share/applications/${pname}.desktop \
          --replace 'Icon=t3code' 'Icon=${pname}'
        chmod -R u+w $out/share/icons
        find $out/share/icons -name 't3code.png' -execdir mv {} '${pname}.png' \;
      fi
    '';

    extraBwrapArgs = [
      "--bind-try /etc/nixos/ /etc/nixos/"
    ];

    dieWithParent = false;

    extraPkgs = pkgs:
      with pkgs; [
        autoPatchelfHook
      ];
  }
