While this +/- follows the core template, it works slightly differently. `hosts` doesn't actually specify hosts, but rather templates, which are then replicated some number of times in flake.nix to `${serverName}:${name}-0`, `${serverName}:${name}-1`, etc.
- `k8s-ca` - one per server microvm running step-ca for internal k8s certificates
    - not HA, but certs don't need to be renewed *that* often anyways so it should be fine
- `k8s-controller` - k8s controllers, runs etcd and control plane stuff
- `k8s-worker` - k8s worker nodes, runs the actual containers
