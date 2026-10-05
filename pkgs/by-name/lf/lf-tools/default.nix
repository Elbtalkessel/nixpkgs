{ pkgs }:
pkgs.nuenv.writeShellApplication {
  name = "preview";
  runtimeInputs = with pkgs; [
    mimeo
    bat
    exiftool
    ouch
    chafa
    ffmpegthumbnailer
    tmsu
    fontconfig
  ];
  text = builtins.readFile ./src/preview.nu;
  meta = {
    mainProgram = "preview";
    description = "File previewer for LF";
  };
}
