# ユーザー鍵 (~/.ssh/id_ed25519) と、各ホストの SSH ホスト鍵。
# ホスト鍵は /etc/ssh/ssh_host_ed25519_key.pub。agenix はこれで復号するので
# (age.identityPaths)、ホストを増やしたらここに足して `agenix -r` が必要。
let
  yuta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGaCUEm+2Pw0mntn5pySflqtS+ao+TOTOaTmJGx5UQm8 yuta@Yuta-PC";
  yutaPc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACRKh0ubKQpPNCukrbWWQbZs3zppLg/4YacAaGWc+K2 root@nixos";
  yuSaboLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPiukFO8RqXc3OXE1evmONK24RxhYtr8/G+HMxtUArX3 root@YuSabo-Laptop";
  allKeys = [ yuta yutaPc yuSaboLaptop ];
in {
  "yuta-password.age".publicKeys = allKeys;
}
