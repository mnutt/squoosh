{ lib }:
f: opts:
let
  derivations = (lib.attrsets.mapAttrsToList f opts);
in
lib.lists.fold (a: b: a // b) { } derivations
