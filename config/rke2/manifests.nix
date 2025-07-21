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
    # TODO?: charts option

    manifestDir = optStr "/var/lib/rancher/rke2/server/manifests";
  };

  config = mkIf cfg.enable (let
    manifests =
      (mapAttrs (name: manifests: "${
          pkgs.concatText "rke2-manifest-${name}.yaml" (
            lib.concatMap (x: [
              yamlDocSeparator
              ((pkgs.formats.yaml {}).generate "rke2-manifest-doc-${name}.yaml" x)
            ])
            manifests
          )
        }")
        cfg.manifests)
      // (mapAttrs (
        name: manifest: "${pkgs.fetchurl {inherit (manifest) url hash;}}"
      ) (lib.attrsets.filterAttrs (n: v: v.enable) cfg.remoteManifests));
  in {
    sops.templates =
      mapAttrs' (name: manifest: {
        name = "rke2/manifests/${name}.yaml";
        value.file = manifest;
      })
      manifests;

    systemd.tmpfiles.settings."10-rke2" =
      mapAttrs' (name: manifest: {
        name = "${cfg.manifestDir}/${name}.yaml";
        value."L+".argument = "/run/secrets/rendered/rke2/manifests/${name}.yaml";
      })
      manifests;
  });
}
