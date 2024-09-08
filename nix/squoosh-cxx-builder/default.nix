{
  pkgs,
  stdenv,
  runCommand,
}:
{
  name,
  nativeBuildInputs ? [ ],
  encoder ? "enc",
  decoder ? "dec",
  ...
}@args:

stdenv.mkDerivation (
  final:
  args
  // {
    inherit name;
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
