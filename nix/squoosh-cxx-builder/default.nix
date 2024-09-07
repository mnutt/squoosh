{
  pkgs,
  stdenv,
  runCommand,
}:
{
  name,
  src,
  nativeBuildInputs ? [ ],
  encoder ? "enc",
  decoder ? "dec",
  ...
}@args:

stdenv.mkDerivation (
  final:
  args
  // {
    inherit name src;
    nativeBuildInputs = [ pkgs.emscripten ] ++ nativeBuildInputs;
    buildPhase = ''
      export HOME=$TMPDIR
      emmake make -j$(nproc)
    '';
    installPhase = ''
      mkdir -p $out
      ${if (encoder != null) then "cp -r ${encoder} $out" else ""}
      ${if (decoder != null) then "cp -r ${decoder} $out" else ""}
    '';
  }
)
