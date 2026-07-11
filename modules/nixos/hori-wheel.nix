# HORI TRUCK CONTROL SYSTEM WHEEL (0f0d:017a) のブレーキ軸を Linux で有効化する。
#
# このホイールの HID レポート記述子は末尾軸の Usage「Slider(0x36)」を 2 回重複
# 宣言している。Windows は重複を別軸として扱うが、Linux の HID パーサは 2 つ目の
# Slider も ABS_THROTTLE に割り当てようとして衝突し、その軸(=ブレーキ)を破棄する。
# 結果 Linux ではブレーキだけ認識されない(アクセル/クラッチ/ステアは動く)。
#
# packages/hori-truck-wheel の out-of-tree カーネルモジュール(report_fixup)で
# 2 つ目の Slider を Dial(0x37) に書き換え、別軸 ABS_RUDDER として露出させる。
# 実機で ABS_RUDDER がブレーキ全域(0〜65535)に反応することを確認済み。
# ゲーム側(ETS2 等)ではこの RUDDER 軸をブレーキに割り当てて使う。
{ config, ... }:
{
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ../../packages/hori-truck-wheel { })
  ];
  boot.kernelModules = [ "hori_truck_wheel" ];
}
