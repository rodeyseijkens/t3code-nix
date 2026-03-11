{
  lib,
  pkgs,
}:

let
  pname = "t3code";
  version = "0.0.10";
  src = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-zcPsaj4JyI8Ul7VZ4wsYvNH91GgKQZBgRADhgVu/zH8=";
  };
  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
  };
in
  pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    pkgs = pkgs;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/t3-code-desktop.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/t3-code-desktop.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    extraBwrapArgs = [
      "--bind-try /etc/nixos/ /etc/nixos/"
    ];

    dieWithParent = false;

    extraPkgs = pkgs: with pkgs; [
      autoPatchelfHook
    ];
  }
