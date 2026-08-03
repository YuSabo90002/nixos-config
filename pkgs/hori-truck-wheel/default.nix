{ lib, stdenv, kernel }:

stdenv.mkDerivation {
  pname = "hori-truck-wheel";
  version = "0.1";

  src = ./.;

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D hori_truck_wheel.ko \
      "$out/lib/modules/${kernel.modDirVersion}/misc/hori_truck_wheel.ko"
    runHook postInstall
  '';

  meta = with lib; {
    description = "HID report_fixup で HORI Truck Control System ホイールの重複 Slider を分離しブレーキ軸を有効化する";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
