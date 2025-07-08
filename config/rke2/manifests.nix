# TODO: https://docs.k3s.io/cli/certificate#using-custom-ca-certificates
{
  pkgs,
  config,
  lib,
  azLib,
  outputs,
  ...
}:
with lib; let
  cfg = config.az.server.rke2;
  yamlDocSeparator = builtins.toFile "yaml-doc-separator" "\n---\n";
in {
  options.az.server.rke2 = with azLib.opt; {
    manifests = mkOption {
      type = with types; attrsOf (listOf attrs);
      default = {};
    };
    remoteManifests = mkOption {
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            enable = optBool true;
            name = optStr name;

            url = mkOption {type = types.str;};
            hash = optStr "";
          };
        }));
      default = {};
    };
    # TODO?: charts

    manifestDir = optStr "/var/lib/rancher/rke2/server/manifests";
  };

  config = mkIf cfg.enable (let
    tmpfiles =
      (mapAttrs' (name: manifests: let
          fName = "${name}.yaml";
        in {
          name = "${cfg.manifestDir}/${fName}";
          value."C".argument = "${
            pkgs.concatText fName (
              # C+, since rke2 needs to be able to write stuff into helm charts
              lib.concatMap (x: [
                yamlDocSeparator
                ((pkgs.formats.yaml {}).generate "rke2-doc-${name}.yaml" x)
              ])
              manifests
            )
          }";
        })
        cfg.manifests)
      // (mapAttrs' (name: manifest: let
          fName = "${manifest.name}.yaml";
        in {
          name = "${cfg.manifestDir}/${fName}";
          value."C".argument = "${pkgs.fetchurl {inherit (manifest) url hash;}}";
        })
        (lib.attrsets.filterAttrs (n: v: v.enable) cfg.remoteManifests));
  in {
    systemd.tmpfiles.settings."09-rke2-pre" = mapAttrs (n: v: {"r" = {};}) tmpfiles; # remove before copying
    systemd.tmpfiles.settings."10-rke2" = tmpfiles;
  });
}
