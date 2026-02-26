let
  yuta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGaCUEm+2Pw0mntn5pySflqtS+ao+TOTOaTmJGx5UQm8 yuta@Yuta-PC";
  host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACRKh0ubKQpPNCukrbWWQbZs3zppLg/4YacAaGWc+K2 root@nixos";
  allKeys = [ yuta host ];
in {
  "yuta-password.age".publicKeys = allKeys;
}
