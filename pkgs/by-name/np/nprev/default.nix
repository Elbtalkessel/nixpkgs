{ pkgs }:
{
  preview = pkgs.nuenv.writeShellApplication {
    name = "nprev";
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
    text = builtins.readFile ./src/nprev.nu;
    meta = {
      mainProgram = "nprev";
      description = "File previewer written in nu.";
    };
  };
}
