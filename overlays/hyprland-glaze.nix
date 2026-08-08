# hyprland 0.56.1 の CMakeLists は `find_package(glaze 7...<8 QUIET)` で glaze 7 系を要求する。
# nixpkgs-unstable の glaze が 8.0.0 に上がったため find_package が失敗し、
# FetchContent での git clone にフォールバックしてサンドボックス内でビルドが落ちる。
# nixpkgs 側が hyprland を glaze 8 対応版へ上げるまで、hyprland にだけ 7.2.0 を注入する。
_final: prev: {
  hyprland = prev.hyprland.override {
    glaze = prev.glaze.overrideAttrs (
      _old: rec {
        version = "7.2.0";
        src = prev.fetchFromGitHub {
          owner = "stephenberry";
          repo = "glaze";
          tag = "v${version}";
          hash = "sha256-f3NVRi3SXKo42hn0WCw7JsOK3EkdOVJIcuzhPorKjFY=";
        };
      }
    );
  };
}
