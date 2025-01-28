#/bin/sh

sudo cp /etc/nixos/configuration.nix ./ && \
sudo chmod 666 ./configuration.nix && \
sudo chown $USER:users ./configuration.nix && \
git add --all && \
git commit -m "Update configuration.nix" && \
git push
