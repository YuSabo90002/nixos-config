{ python3Packages, fetchPypi }:

python3Packages.buildPythonApplication {
  pname = "specify-cli";
  version = "1.0.0";
  pyproject = true;

  src = fetchPypi {
    pname = "specify_cli";
    version = "1.0.0";
    hash = "sha256-Wwj9xDyR5st0x/lFUqrD58gd3XXL//OdVH7JP3S/Gzs=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    typer
    click
    rich
    httpx
    socksio
    platformdirs
    readchar
    truststore
    pyyaml
    packaging
  ];
}
