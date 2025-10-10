{pkgs, ...}: {
  # args: --repo https://cloudnative-pg.github.io/charts cloudnative-pg --version 0.26.0
  config.services.rke2.images = builtins.map pkgs.dockerTools.pullImage [
    {
      imageName = "Always";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "kubelet";
      imageDigest = "";
      hash = "";
      finalImageTag = "kubelet";
    }
    {
      imageName = "always";
      imageDigest = "";
      hash = "";
      finalImageTag = "always";
    }
    {
      imageName = "attempts";
      imageDigest = "";
      hash = "";
      finalImageTag = "attempts";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference.";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference.";
    }
    {
      imageName = "Container";
      imageDigest = "";
      hash = "";
      finalImageTag = "Container";
    }
    {
      imageName = "creation";
      imageDigest = "";
      hash = "";
      finalImageTag = "creation";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "fail";
      imageDigest = "";
      hash = "";
      finalImageTag = "fail";
    }
    {
      imageName = "If";
      imageDigest = "";
      hash = "";
      finalImageTag = "If";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "fails.";
      imageDigest = "";
      hash = "";
      finalImageTag = "fails.";
    }
    {
      imageName = "Behaves";
      imageDigest = "";
      hash = "";
      finalImageTag = "Behaves";
    }
    {
      imageName = "in";
      imageDigest = "";
      hash = "";
      finalImageTag = "in";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "same";
      imageDigest = "";
      hash = "";
      finalImageTag = "same";
    }
    {
      imageName = "way";
      imageDigest = "";
      hash = "";
      finalImageTag = "way";
    }
    {
      imageName = "as";
      imageDigest = "";
      hash = "";
      finalImageTag = "as";
    }
    {
      imageName = "pod.spec.containers[*].image.";
      imageDigest = "";
      hash = "";
      finalImageTag = "pod.spec.containers[*].image.";
    }
    {
      imageName = "Defaults";
      imageDigest = "";
      hash = "";
      finalImageTag = "Defaults";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "Always";
      imageDigest = "";
      hash = "";
      finalImageTag = "Always";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "latest";
    }
    {
      imageName = "tag";
      imageDigest = "";
      hash = "";
      finalImageTag = "tag";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "specified,";
      imageDigest = "";
      hash = "";
      finalImageTag = "specified,";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "IfNotPresent";
      imageDigest = "";
      hash = "";
      finalImageTag = "IfNotPresent";
    }
    {
      imageName = "otherwise.";
      imageDigest = "";
      hash = "";
      finalImageTag = "otherwise.";
    }
    {
      imageName = "IfNotPresent";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "kubelet";
      imageDigest = "";
      hash = "";
      finalImageTag = "kubelet";
    }
    {
      imageName = "pulls";
      imageDigest = "";
      hash = "";
      finalImageTag = "pulls";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "isn't";
      imageDigest = "";
      hash = "";
      finalImageTag = "isn't";
    }
    {
      imageName = "already";
      imageDigest = "";
      hash = "";
      finalImageTag = "already";
    }
    {
      imageName = "present";
      imageDigest = "";
      hash = "";
      finalImageTag = "present";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "disk.";
      imageDigest = "";
      hash = "";
      finalImageTag = "disk.";
    }
    {
      imageName = "Container";
      imageDigest = "";
      hash = "";
      finalImageTag = "Container";
    }
    {
      imageName = "creation";
      imageDigest = "";
      hash = "";
      finalImageTag = "creation";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "fail";
      imageDigest = "";
      hash = "";
      finalImageTag = "fail";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "isn't";
      imageDigest = "";
      hash = "";
      finalImageTag = "isn't";
    }
    {
      imageName = "present";
      imageDigest = "";
      hash = "";
      finalImageTag = "present";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "fails.";
      imageDigest = "";
      hash = "";
      finalImageTag = "fails.";
    }
    {
      imageName = "More";
      imageDigest = "";
      hash = "";
      finalImageTag = "More";
    }
    {
      imageName = "info";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "https";
      imageDigest = "";
      hash = "";
      finalImageTag = "//kubernetes.io/docs/concepts/containers/images";
    }
    {
      imageName = "Never";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "kubelet";
      imageDigest = "";
      hash = "";
      finalImageTag = "kubelet";
    }
    {
      imageName = "never";
      imageDigest = "";
      hash = "";
      finalImageTag = "never";
    }
    {
      imageName = "pulls";
      imageDigest = "";
      hash = "";
      finalImageTag = "pulls";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "only";
      imageDigest = "";
      hash = "";
      finalImageTag = "only";
    }
    {
      imageName = "uses";
      imageDigest = "";
      hash = "";
      finalImageTag = "uses";
    }
    {
      imageName = "a";
      imageDigest = "";
      hash = "";
      finalImageTag = "a";
    }
    {
      imageName = "local";
      imageDigest = "";
      hash = "";
      finalImageTag = "local";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "artifact.";
      imageDigest = "";
      hash = "";
      finalImageTag = "artifact.";
    }
    {
      imageName = "Container";
      imageDigest = "";
      hash = "";
      finalImageTag = "Container";
    }
    {
      imageName = "creation";
      imageDigest = "";
      hash = "";
      finalImageTag = "creation";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "fail";
      imageDigest = "";
      hash = "";
      finalImageTag = "fail";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "isn't";
      imageDigest = "";
      hash = "";
      finalImageTag = "isn't";
    }
    {
      imageName = "present.";
      imageDigest = "";
      hash = "";
      finalImageTag = "present.";
    }
    {
      imageName = "Policy";
      imageDigest = "";
      hash = "";
      finalImageTag = "Policy";
    }
    {
      imageName = "for";
      imageDigest = "";
      hash = "";
      finalImageTag = "for";
    }
    {
      imageName = "pulling";
      imageDigest = "";
      hash = "";
      finalImageTag = "pulling";
    }
    {
      imageName = "OCI";
      imageDigest = "";
      hash = "";
      finalImageTag = "OCI";
    }
    {
      imageName = "objects.";
      imageDigest = "";
      hash = "";
      finalImageTag = "objects.";
    }
    {
      imageName = "Possible";
      imageDigest = "";
      hash = "";
      finalImageTag = "Possible";
    }
    {
      imageName = "values";
      imageDigest = "";
      hash = "";
      finalImageTag = "values";
    }
    {
      imageName = "are";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "Pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "Pull";
    }
    {
      imageName = "secrets";
      imageDigest = "";
      hash = "";
      finalImageTag = "secrets";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "be";
      imageDigest = "";
      hash = "";
      finalImageTag = "be";
    }
    {
      imageName = "assembled";
      imageDigest = "";
      hash = "";
      finalImageTag = "assembled";
    }
    {
      imageName = "in";
      imageDigest = "";
      hash = "";
      finalImageTag = "in";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "same";
      imageDigest = "";
      hash = "";
      finalImageTag = "same";
    }
    {
      imageName = "way";
      imageDigest = "";
      hash = "";
      finalImageTag = "way";
    }
    {
      imageName = "as";
      imageDigest = "";
      hash = "";
      finalImageTag = "as";
    }
    {
      imageName = "for";
      imageDigest = "";
      hash = "";
      finalImageTag = "for";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "container";
      imageDigest = "";
      hash = "";
      finalImageTag = "container";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "by";
      imageDigest = "";
      hash = "";
      finalImageTag = "by";
    }
    {
      imageName = "looking";
      imageDigest = "";
      hash = "";
      finalImageTag = "looking";
    }
    {
      imageName = "up";
      imageDigest = "";
      hash = "";
      finalImageTag = "up";
    }
    {
      imageName = "node";
      imageDigest = "sha256:377f1c17906eb5a145c34000247faa486bece16386b77eedd5a236335025c2ef";
      hash = "sha256-kLXNVJEoEugvUaFqCqRNFbf9KmIRR0bnGBNksX4AvaY=";
      finalImageTag = "node";
    }
    {
      imageName = "credentials,";
      imageDigest = "";
      hash = "";
      finalImageTag = "credentials,";
    }
    {
      imageName = "SA";
      imageDigest = "";
      hash = "";
      finalImageTag = "SA";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "secrets,";
      imageDigest = "";
      hash = "";
      finalImageTag = "secrets,";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "pod";
      imageDigest = "";
      hash = "";
      finalImageTag = "pod";
    }
    {
      imageName = "spec";
      imageDigest = "";
      hash = "";
      finalImageTag = "spec";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "secrets.";
      imageDigest = "";
      hash = "";
      finalImageTag = "secrets.";
    }
    {
      imageName = "Required";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "Image";
      imageDigest = "";
      hash = "";
      finalImageTag = "Image";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "artifact";
      imageDigest = "";
      hash = "";
      finalImageTag = "artifact";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "be";
      imageDigest = "";
      hash = "";
      finalImageTag = "be";
    }
    {
      imageName = "used.";
      imageDigest = "";
      hash = "";
      finalImageTag = "used.";
    }
    {
      imageName = "This";
      imageDigest = "";
      hash = "";
      finalImageTag = "This";
    }
    {
      imageName = "field";
      imageDigest = "";
      hash = "";
      finalImageTag = "field";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "optional";
      imageDigest = "";
      hash = "";
      finalImageTag = "optional";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "allow";
      imageDigest = "";
      hash = "";
      finalImageTag = "allow";
    }
    {
      imageName = "higher";
      imageDigest = "";
      hash = "";
      finalImageTag = "higher";
    }
    {
      imageName = "level";
      imageDigest = "";
      hash = "";
      finalImageTag = "level";
    }
    {
      imageName = "config";
      imageDigest = "";
      hash = "";
      finalImageTag = "config";
    }
    {
      imageName = "management";
      imageDigest = "";
      hash = "";
      finalImageTag = "management";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "default";
      imageDigest = "";
      hash = "";
      finalImageTag = "default";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "override";
      imageDigest = "";
      hash = "";
      finalImageTag = "override";
    }
    {
      imageName = "container";
      imageDigest = "";
      hash = "";
      finalImageTag = "container";
    }
    {
      imageName = "images";
      imageDigest = "";
      hash = "";
      finalImageTag = "images";
    }
    {
      imageName = "in";
      imageDigest = "";
      hash = "";
      finalImageTag = "in";
    }
    {
      imageName = "workload";
      imageDigest = "";
      hash = "";
      finalImageTag = "workload";
    }
    {
      imageName = "controllers";
      imageDigest = "";
      hash = "";
      finalImageTag = "controllers";
    }
    {
      imageName = "like";
      imageDigest = "";
      hash = "";
      finalImageTag = "like";
    }
    {
      imageName = "Deployments";
      imageDigest = "";
      hash = "";
      finalImageTag = "Deployments";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "StatefulSets.";
      imageDigest = "";
      hash = "";
      finalImageTag = "StatefulSets.";
    }
    {
      imageName = "description";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "|-";
      imageDigest = "";
      hash = "";
      finalImageTag = "|-";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "null";
      imageDigest = "";
      hash = "";
      finalImageTag = "null";
    }
    {
      imageName = "rule";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "has(self.reference)";
      imageDigest = "";
      hash = "";
      finalImageTag = "has(self.reference)";
    }
    {
      imageName = "type";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "string";
      imageDigest = "";
      hash = "";
      finalImageTag = "string";
    }
    {
      imageName = "-";
      imageDigest = "";
      hash = "";
      finalImageTag = "-";
    }
    {
      imageName = "Always";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "kubelet";
      imageDigest = "";
      hash = "";
      finalImageTag = "kubelet";
    }
    {
      imageName = "always";
      imageDigest = "";
      hash = "";
      finalImageTag = "always";
    }
    {
      imageName = "attempts";
      imageDigest = "";
      hash = "";
      finalImageTag = "attempts";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference.";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference.";
    }
    {
      imageName = "Container";
      imageDigest = "";
      hash = "";
      finalImageTag = "Container";
    }
    {
      imageName = "creation";
      imageDigest = "";
      hash = "";
      finalImageTag = "creation";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "fail";
      imageDigest = "";
      hash = "";
      finalImageTag = "fail";
    }
    {
      imageName = "If";
      imageDigest = "";
      hash = "";
      finalImageTag = "If";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "fails.";
      imageDigest = "";
      hash = "";
      finalImageTag = "fails.";
    }
    {
      imageName = "-";
      imageDigest = "";
      hash = "";
      finalImageTag = "-";
    }
    {
      imageName = "IfNotPresent";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "kubelet";
      imageDigest = "";
      hash = "";
      finalImageTag = "kubelet";
    }
    {
      imageName = "pulls";
      imageDigest = "";
      hash = "";
      finalImageTag = "pulls";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "isn't";
      imageDigest = "";
      hash = "";
      finalImageTag = "isn't";
    }
    {
      imageName = "already";
      imageDigest = "";
      hash = "";
      finalImageTag = "already";
    }
    {
      imageName = "present";
      imageDigest = "";
      hash = "";
      finalImageTag = "present";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "disk.";
      imageDigest = "";
      hash = "";
      finalImageTag = "disk.";
    }
    {
      imageName = "Container";
      imageDigest = "";
      hash = "";
      finalImageTag = "Container";
    }
    {
      imageName = "creation";
      imageDigest = "";
      hash = "";
      finalImageTag = "creation";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "fail";
      imageDigest = "";
      hash = "";
      finalImageTag = "fail";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "isn't";
      imageDigest = "";
      hash = "";
      finalImageTag = "isn't";
    }
    {
      imageName = "present";
      imageDigest = "";
      hash = "";
      finalImageTag = "present";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "fails.";
      imageDigest = "";
      hash = "";
      finalImageTag = "fails.";
    }
    {
      imageName = "-";
      imageDigest = "";
      hash = "";
      finalImageTag = "-";
    }
    {
      imageName = "Never";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "kubelet";
      imageDigest = "";
      hash = "";
      finalImageTag = "kubelet";
    }
    {
      imageName = "never";
      imageDigest = "";
      hash = "";
      finalImageTag = "never";
    }
    {
      imageName = "pulls";
      imageDigest = "";
      hash = "";
      finalImageTag = "pulls";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "only";
      imageDigest = "";
      hash = "";
      finalImageTag = "only";
    }
    {
      imageName = "uses";
      imageDigest = "";
      hash = "";
      finalImageTag = "uses";
    }
    {
      imageName = "a";
      imageDigest = "";
      hash = "";
      finalImageTag = "a";
    }
    {
      imageName = "local";
      imageDigest = "";
      hash = "";
      finalImageTag = "local";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "artifact.";
      imageDigest = "";
      hash = "";
      finalImageTag = "artifact.";
    }
    {
      imageName = "Container";
      imageDigest = "";
      hash = "";
      finalImageTag = "Container";
    }
    {
      imageName = "creation";
      imageDigest = "";
      hash = "";
      finalImageTag = "creation";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "fail";
      imageDigest = "";
      hash = "";
      finalImageTag = "fail";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "isn't";
      imageDigest = "";
      hash = "";
      finalImageTag = "isn't";
    }
    {
      imageName = "present.";
      imageDigest = "";
      hash = "";
      finalImageTag = "present.";
    }
    {
      imageName = "-";
      imageDigest = "";
      hash = "";
      finalImageTag = "-";
    }
    {
      imageName = "message";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "An";
      imageDigest = "";
      hash = "";
      finalImageTag = "An";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "required";
      imageDigest = "";
      hash = "";
      finalImageTag = "required";
    }
    {
      imageName = "A";
      imageDigest = "";
      hash = "";
      finalImageTag = "A";
    }
    {
      imageName = "failure";
      imageDigest = "";
      hash = "";
      finalImageTag = "failure";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "resolve";
      imageDigest = "";
      hash = "";
      finalImageTag = "resolve";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "pull";
      imageDigest = "";
      hash = "";
      finalImageTag = "pull";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "during";
      imageDigest = "";
      hash = "";
      finalImageTag = "during";
    }
    {
      imageName = "pod";
      imageDigest = "";
      hash = "";
      finalImageTag = "pod";
    }
    {
      imageName = "startup";
      imageDigest = "";
      hash = "";
      finalImageTag = "startup";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "block";
      imageDigest = "";
      hash = "";
      finalImageTag = "block";
    }
    {
      imageName = "containers";
      imageDigest = "";
      hash = "";
      finalImageTag = "containers";
    }
    {
      imageName = "from";
      imageDigest = "";
      hash = "";
      finalImageTag = "from";
    }
    {
      imageName = "starting";
      imageDigest = "";
      hash = "";
      finalImageTag = "starting";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "may";
      imageDigest = "";
      hash = "";
      finalImageTag = "may";
    }
    {
      imageName = "add";
      imageDigest = "";
      hash = "";
      finalImageTag = "add";
    }
    {
      imageName = "significant";
      imageDigest = "";
      hash = "";
      finalImageTag = "significant";
    }
    {
      imageName = "latency.";
      imageDigest = "";
      hash = "";
      finalImageTag = "latency.";
    }
    {
      imageName = "Failures";
      imageDigest = "";
      hash = "";
      finalImageTag = "Failures";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "be";
      imageDigest = "";
      hash = "";
      finalImageTag = "be";
    }
    {
      imageName = "retried";
      imageDigest = "";
      hash = "";
      finalImageTag = "retried";
    }
    {
      imageName = "using";
      imageDigest = "";
      hash = "";
      finalImageTag = "using";
    }
    {
      imageName = "normal";
      imageDigest = "";
      hash = "";
      finalImageTag = "normal";
    }
    {
      imageName = "volume";
      imageDigest = "";
      hash = "";
      finalImageTag = "volume";
    }
    {
      imageName = "backoff";
      imageDigest = "";
      hash = "";
      finalImageTag = "backoff";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "be";
      imageDigest = "";
      hash = "";
      finalImageTag = "be";
    }
    {
      imageName = "reported";
      imageDigest = "";
      hash = "";
      finalImageTag = "reported";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "pod";
      imageDigest = "";
      hash = "";
      finalImageTag = "pod";
    }
    {
      imageName = "reason";
      imageDigest = "";
      hash = "";
      finalImageTag = "reason";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "message.";
      imageDigest = "";
      hash = "";
      finalImageTag = "message.";
    }
    {
      imageName = "Container";
      imageDigest = "";
      hash = "";
      finalImageTag = "Container";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "name.";
      imageDigest = "";
      hash = "";
      finalImageTag = "name.";
    }
    {
      imageName = "More";
      imageDigest = "";
      hash = "";
      finalImageTag = "More";
    }
    {
      imageName = "info";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "https";
      imageDigest = "";
      hash = "";
      finalImageTag = "//examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
    }
    {
      imageName = "More";
      imageDigest = "";
      hash = "";
      finalImageTag = "More";
    }
    {
      imageName = "info";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "https";
      imageDigest = "";
      hash = "";
      finalImageTag = "//kubernetes.io/docs/concepts/containers/images";
    }
    {
      imageName = "Sub";
      imageDigest = "";
      hash = "";
      finalImageTag = "Sub";
    }
    {
      imageName = "path";
      imageDigest = "";
      hash = "";
      finalImageTag = "path";
    }
    {
      imageName = "mounts";
      imageDigest = "";
      hash = "";
      finalImageTag = "mounts";
    }
    {
      imageName = "for";
      imageDigest = "";
      hash = "";
      finalImageTag = "for";
    }
    {
      imageName = "containers";
      imageDigest = "";
      hash = "";
      finalImageTag = "containers";
    }
    {
      imageName = "are";
      imageDigest = "";
      hash = "";
      finalImageTag = "are";
    }
    {
      imageName = "not";
      imageDigest = "";
      hash = "";
      finalImageTag = "not";
    }
    {
      imageName = "supported";
      imageDigest = "";
      hash = "";
      finalImageTag = "supported";
    }
    {
      imageName = "(spec.containers[*].volumeMounts.subpath)";
      imageDigest = "";
      hash = "";
      finalImageTag = "(spec.containers[*].volumeMounts.subpath)";
    }
    {
      imageName = "before";
      imageDigest = "";
      hash = "";
      finalImageTag = "before";
    }
    {
      imageName = "1.33.";
      imageDigest = "";
      hash = "";
      finalImageTag = "1.33.";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "OCI";
      imageDigest = "";
      hash = "";
      finalImageTag = "OCI";
    }
    {
      imageName = "object";
      imageDigest = "";
      hash = "";
      finalImageTag = "object";
    }
    {
      imageName = "gets";
      imageDigest = "";
      hash = "";
      finalImageTag = "gets";
    }
    {
      imageName = "mounted";
      imageDigest = "";
      hash = "";
      finalImageTag = "mounted";
    }
    {
      imageName = "in";
      imageDigest = "";
      hash = "";
      finalImageTag = "in";
    }
    {
      imageName = "a";
      imageDigest = "";
      hash = "";
      finalImageTag = "a";
    }
    {
      imageName = "single";
      imageDigest = "";
      hash = "";
      finalImageTag = "single";
    }
    {
      imageName = "directory";
      imageDigest = "";
      hash = "";
      finalImageTag = "directory";
    }
    {
      imageName = "(spec.containers[*].volumeMounts.mountPath)";
      imageDigest = "";
      hash = "";
      finalImageTag = "(spec.containers[*].volumeMounts.mountPath)";
    }
    {
      imageName = "by";
      imageDigest = "";
      hash = "";
      finalImageTag = "by";
    }
    {
      imageName = "merging";
      imageDigest = "";
      hash = "";
      finalImageTag = "merging";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "manifest";
      imageDigest = "";
      hash = "";
      finalImageTag = "manifest";
    }
    {
      imageName = "layers";
      imageDigest = "";
      hash = "";
      finalImageTag = "layers";
    }
    {
      imageName = "in";
      imageDigest = "";
      hash = "";
      finalImageTag = "in";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "same";
      imageDigest = "";
      hash = "";
      finalImageTag = "same";
    }
    {
      imageName = "way";
      imageDigest = "";
      hash = "";
      finalImageTag = "way";
    }
    {
      imageName = "as";
      imageDigest = "";
      hash = "";
      finalImageTag = "as";
    }
    {
      imageName = "for";
      imageDigest = "";
      hash = "";
      finalImageTag = "for";
    }
    {
      imageName = "container";
      imageDigest = "";
      hash = "";
      finalImageTag = "container";
    }
    {
      imageName = "images.";
      imageDigest = "";
      hash = "";
      finalImageTag = "images.";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "field";
      imageDigest = "";
      hash = "";
      finalImageTag = "field";
    }
    {
      imageName = "spec.securityContext.fsGroupChangePolicy";
      imageDigest = "";
      hash = "";
      finalImageTag = "spec.securityContext.fsGroupChangePolicy";
    }
    {
      imageName = "has";
      imageDigest = "";
      hash = "";
      finalImageTag = "has";
    }
    {
      imageName = "no";
      imageDigest = "";
      hash = "";
      finalImageTag = "no";
    }
    {
      imageName = "effect";
      imageDigest = "";
      hash = "";
      finalImageTag = "effect";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "this";
      imageDigest = "";
      hash = "";
      finalImageTag = "this";
    }
    {
      imageName = "volume";
      imageDigest = "";
      hash = "";
      finalImageTag = "volume";
    }
    {
      imageName = "type.";
      imageDigest = "";
      hash = "";
      finalImageTag = "type.";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "types";
      imageDigest = "";
      hash = "";
      finalImageTag = "types";
    }
    {
      imageName = "of";
      imageDigest = "";
      hash = "";
      finalImageTag = "of";
    }
    {
      imageName = "objects";
      imageDigest = "";
      hash = "";
      finalImageTag = "objects";
    }
    {
      imageName = "that";
      imageDigest = "";
      hash = "";
      finalImageTag = "that";
    }
    {
      imageName = "may";
      imageDigest = "";
      hash = "";
      finalImageTag = "may";
    }
    {
      imageName = "be";
      imageDigest = "";
      hash = "";
      finalImageTag = "be";
    }
    {
      imageName = "mounted";
      imageDigest = "";
      hash = "";
      finalImageTag = "mounted";
    }
    {
      imageName = "by";
      imageDigest = "";
      hash = "";
      finalImageTag = "by";
    }
    {
      imageName = "this";
      imageDigest = "";
      hash = "";
      finalImageTag = "this";
    }
    {
      imageName = "volume";
      imageDigest = "";
      hash = "";
      finalImageTag = "volume";
    }
    {
      imageName = "are";
      imageDigest = "";
      hash = "";
      finalImageTag = "are";
    }
    {
      imageName = "defined";
      imageDigest = "";
      hash = "";
      finalImageTag = "defined";
    }
    {
      imageName = "by";
      imageDigest = "";
      hash = "";
      finalImageTag = "by";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "container";
      imageDigest = "";
      hash = "";
      finalImageTag = "container";
    }
    {
      imageName = "runtime";
      imageDigest = "";
      hash = "";
      finalImageTag = "runtime";
    }
    {
      imageName = "implementation";
      imageDigest = "";
      hash = "";
      finalImageTag = "implementation";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "a";
      imageDigest = "";
      hash = "";
      finalImageTag = "a";
    }
    {
      imageName = "host";
      imageDigest = "";
      hash = "";
      finalImageTag = "host";
    }
    {
      imageName = "machine";
      imageDigest = "";
      hash = "";
      finalImageTag = "machine";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "at";
      imageDigest = "";
      hash = "";
      finalImageTag = "at";
    }
    {
      imageName = "minimum";
      imageDigest = "";
      hash = "";
      finalImageTag = "minimum";
    }
    {
      imageName = "must";
      imageDigest = "";
      hash = "";
      finalImageTag = "must";
    }
    {
      imageName = "include";
      imageDigest = "";
      hash = "";
      finalImageTag = "include";
    }
    {
      imageName = "all";
      imageDigest = "";
      hash = "";
      finalImageTag = "all";
    }
    {
      imageName = "valid";
      imageDigest = "";
      hash = "";
      finalImageTag = "valid";
    }
    {
      imageName = "types";
      imageDigest = "";
      hash = "";
      finalImageTag = "types";
    }
    {
      imageName = "supported";
      imageDigest = "";
      hash = "";
      finalImageTag = "supported";
    }
    {
      imageName = "by";
      imageDigest = "";
      hash = "";
      finalImageTag = "by";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "container";
      imageDigest = "";
      hash = "";
      finalImageTag = "container";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "field.";
      imageDigest = "";
      hash = "";
      finalImageTag = "field.";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "volume";
      imageDigest = "";
      hash = "";
      finalImageTag = "volume";
    }
    {
      imageName = "gets";
      imageDigest = "";
      hash = "";
      finalImageTag = "gets";
    }
    {
      imageName = "re-resolved";
      imageDigest = "";
      hash = "";
      finalImageTag = "re-resolved";
    }
    {
      imageName = "if";
      imageDigest = "";
      hash = "";
      finalImageTag = "if";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "pod";
      imageDigest = "";
      hash = "";
      finalImageTag = "pod";
    }
    {
      imageName = "gets";
      imageDigest = "";
      hash = "";
      finalImageTag = "gets";
    }
    {
      imageName = "deleted";
      imageDigest = "";
      hash = "";
      finalImageTag = "deleted";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "recreated,";
      imageDigest = "";
      hash = "";
      finalImageTag = "recreated,";
    }
    {
      imageName = "which";
      imageDigest = "";
      hash = "";
      finalImageTag = "which";
    }
    {
      imageName = "means";
      imageDigest = "";
      hash = "";
      finalImageTag = "means";
    }
    {
      imageName = "that";
      imageDigest = "";
      hash = "";
      finalImageTag = "that";
    }
    {
      imageName = "new";
      imageDigest = "";
      hash = "";
      finalImageTag = "new";
    }
    {
      imageName = "remote";
      imageDigest = "";
      hash = "";
      finalImageTag = "remote";
    }
    {
      imageName = "content";
      imageDigest = "";
      hash = "";
      finalImageTag = "content";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "become";
      imageDigest = "";
      hash = "";
      finalImageTag = "become";
    }
    {
      imageName = "available";
      imageDigest = "";
      hash = "";
      finalImageTag = "available";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "pod";
      imageDigest = "";
      hash = "";
      finalImageTag = "pod";
    }
    {
      imageName = "recreation.";
      imageDigest = "";
      hash = "";
      finalImageTag = "recreation.";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "volume";
      imageDigest = "";
      hash = "";
      finalImageTag = "volume";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "resolved";
      imageDigest = "";
      hash = "";
      finalImageTag = "resolved";
    }
    {
      imageName = "at";
      imageDigest = "";
      hash = "";
      finalImageTag = "at";
    }
    {
      imageName = "pod";
      imageDigest = "";
      hash = "";
      finalImageTag = "pod";
    }
    {
      imageName = "startup";
      imageDigest = "";
      hash = "";
      finalImageTag = "startup";
    }
    {
      imageName = "depending";
      imageDigest = "";
      hash = "";
      finalImageTag = "depending";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "which";
      imageDigest = "";
      hash = "";
      finalImageTag = "which";
    }
    {
      imageName = "PullPolicy";
      imageDigest = "";
      hash = "";
      finalImageTag = "PullPolicy";
    }
    {
      imageName = "value";
      imageDigest = "";
      hash = "";
      finalImageTag = "value";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "provided";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "volume";
      imageDigest = "";
      hash = "";
      finalImageTag = "volume";
    }
    {
      imageName = "will";
      imageDigest = "";
      hash = "";
      finalImageTag = "will";
    }
    {
      imageName = "be";
      imageDigest = "";
      hash = "";
      finalImageTag = "be";
    }
    {
      imageName = "mounted";
      imageDigest = "";
      hash = "";
      finalImageTag = "mounted";
    }
    {
      imageName = "read-only";
      imageDigest = "";
      hash = "";
      finalImageTag = "read-only";
    }
    {
      imageName = "(ro)";
      imageDigest = "";
      hash = "";
      finalImageTag = "(ro)";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "non-executable";
      imageDigest = "";
      hash = "";
      finalImageTag = "non-executable";
    }
    {
      imageName = "files";
      imageDigest = "";
      hash = "";
      finalImageTag = "files";
    }
    {
      imageName = "(noexec).";
      imageDigest = "";
      hash = "";
      finalImageTag = "(noexec).";
    }
    {
      imageName = "This";
      imageDigest = "";
      hash = "";
      finalImageTag = "This";
    }
    {
      imageName = "field";
      imageDigest = "";
      hash = "";
      finalImageTag = "field";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "optional";
      imageDigest = "";
      hash = "";
      finalImageTag = "optional";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "allow";
      imageDigest = "";
      hash = "";
      finalImageTag = "allow";
    }
    {
      imageName = "higher";
      imageDigest = "";
      hash = "";
      finalImageTag = "higher";
    }
    {
      imageName = "level";
      imageDigest = "";
      hash = "";
      finalImageTag = "level";
    }
    {
      imageName = "config";
      imageDigest = "";
      hash = "";
      finalImageTag = "config";
    }
    {
      imageName = "management";
      imageDigest = "";
      hash = "";
      finalImageTag = "management";
    }
    {
      imageName = "to";
      imageDigest = "";
      hash = "";
      finalImageTag = "to";
    }
    {
      imageName = "default";
      imageDigest = "";
      hash = "";
      finalImageTag = "default";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "override";
      imageDigest = "";
      hash = "";
      finalImageTag = "override";
    }
    {
      imageName = "container";
      imageDigest = "";
      hash = "";
      finalImageTag = "container";
    }
    {
      imageName = "images";
      imageDigest = "";
      hash = "";
      finalImageTag = "images";
    }
    {
      imageName = "in";
      imageDigest = "";
      hash = "";
      finalImageTag = "in";
    }
    {
      imageName = "workload";
      imageDigest = "";
      hash = "";
      finalImageTag = "workload";
    }
    {
      imageName = "controllers";
      imageDigest = "";
      hash = "";
      finalImageTag = "controllers";
    }
    {
      imageName = "like";
      imageDigest = "";
      hash = "";
      finalImageTag = "like";
    }
    {
      imageName = "Deployments";
      imageDigest = "";
      hash = "";
      finalImageTag = "Deployments";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "StatefulSets.";
      imageDigest = "";
      hash = "";
      finalImageTag = "StatefulSets.";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "rados";
      imageDigest = "";
      hash = "";
      finalImageTag = "rados";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "name.";
      imageDigest = "";
      hash = "";
      finalImageTag = "name.";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "represents";
      imageDigest = "";
      hash = "";
      finalImageTag = "represents";
    }
    {
      imageName = "an";
      imageDigest = "";
      hash = "";
      finalImageTag = "an";
    }
    {
      imageName = "OCI";
      imageDigest = "";
      hash = "";
      finalImageTag = "OCI";
    }
    {
      imageName = "object";
      imageDigest = "";
      hash = "";
      finalImageTag = "object";
    }
    {
      imageName = "(a";
      imageDigest = "";
      hash = "";
      finalImageTag = "(a";
    }
    {
      imageName = "container";
      imageDigest = "";
      hash = "";
      finalImageTag = "container";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "or";
      imageDigest = "";
      hash = "";
      finalImageTag = "or";
    }
    {
      imageName = "artifact)";
      imageDigest = "";
      hash = "";
      finalImageTag = "artifact)";
    }
    {
      imageName = "pulled";
      imageDigest = "";
      hash = "";
      finalImageTag = "pulled";
    }
    {
      imageName = "and";
      imageDigest = "";
      hash = "";
      finalImageTag = "and";
    }
    {
      imageName = "mounted";
      imageDigest = "";
      hash = "";
      finalImageTag = "mounted";
    }
    {
      imageName = "on";
      imageDigest = "";
      hash = "";
      finalImageTag = "on";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "kubelet's";
      imageDigest = "";
      hash = "";
      finalImageTag = "kubelet's";
    }
    {
      imageName = "host";
      imageDigest = "";
      hash = "";
      finalImageTag = "host";
    }
    {
      imageName = "machine.";
      imageDigest = "";
      hash = "";
      finalImageTag = "machine.";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "null";
      imageDigest = "";
      hash = "";
      finalImageTag = "null";
    }
    {
      imageName = "pullPolicy";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "description";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "Image";
      imageDigest = "";
      hash = "";
      finalImageTag = "Image";
    }
    {
      imageName = "contains";
      imageDigest = "";
      hash = "";
      finalImageTag = "contains";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "name";
      imageDigest = "";
      hash = "";
      finalImageTag = "name";
    }
    {
      imageName = "used";
      imageDigest = "";
      hash = "";
      finalImageTag = "used";
    }
    {
      imageName = "by";
      imageDigest = "";
      hash = "";
      finalImageTag = "by";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "pods";
      imageDigest = "";
      hash = "";
      finalImageTag = "pods";
    }
    {
      imageName = "description";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "Image";
      imageDigest = "";
      hash = "";
      finalImageTag = "Image";
    }
    {
      imageName = "is";
      imageDigest = "";
      hash = "";
      finalImageTag = "is";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "name";
      imageDigest = "";
      hash = "";
      finalImageTag = "name";
    }
    {
      imageName = "description";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "containing";
      imageDigest = "";
      hash = "";
      finalImageTag = "containing";
    }
    {
      imageName = "the";
      imageDigest = "";
      hash = "";
      finalImageTag = "the";
    }
    {
      imageName = "extension,";
      imageDigest = "";
      hash = "";
      finalImageTag = "extension,";
    }
    {
      imageName = "required";
      imageDigest = "";
      hash = "";
      finalImageTag = "required";
    }
    {
      imageName = "description";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "The";
      imageDigest = "";
      hash = "";
      finalImageTag = "The";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "image";
    }
    {
      imageName = "reference";
      imageDigest = "";
      hash = "";
      finalImageTag = "reference";
    }
    {
      imageName = "description";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "|-";
      imageDigest = "";
      hash = "";
      finalImageTag = "|-";
    }
    {
      imageName = "ghcr.io/cloudnative-pg/cloudnative-pg";
      imageDigest = "sha256:9e5633b36f1f3ff0bb28b434ce51c95fbb8428a4ab47bc738ea403eb09dbf945";
      hash = "sha256-urcMBhBEH9+USWQnUP5xERr45iBOjhdZs8zrErBtOK4=";
      finalImageTag = "1.27.0";
    }
    {
      imageName = "image";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "null";
      imageDigest = "";
      hash = "";
      finalImageTag = "null";
    }
    {
      imageName = "properties";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "type";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "object";
      imageDigest = "";
      hash = "";
      finalImageTag = "object";
    }
    {
      imageName = "type";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
    {
      imageName = "string";
      imageDigest = "";
      hash = "";
      finalImageTag = "string";
    }
    {
      imageName = "x-kubernetes-validations";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    }
  ];
}
