#!/usr/bin/env sh

echo CLIENTID:
nix-shell -p authelia --run 'authelia crypto rand --length 72 --charset rfc3986'
echo CLIENTSECRET:
nix-shell -p authelia --run 'authelia crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.charset rfc3986'
