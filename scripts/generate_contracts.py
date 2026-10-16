"""Regenerate typed contracts, or fail if committed output differs from the spec."""

import argparse
import re
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "packages/contracts"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    inputs = [(ROOT / "docs/10_API_OPENAPI.yaml", "openapi", "api")]
    for source in sorted((ROOT / "docs/11_EVENT_SCHEMAS").glob("*.schema.json")):
        name = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", source.name.removesuffix(".schema.json"))
        name = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name).lower()
        inputs.append((source, "jsonschema", name))

    with TemporaryDirectory(prefix="cic-contracts-") as directory:
        temporary = Path(directory)
        outputs: list[tuple[Path, Path]] = []
        for source, source_type, name in inputs:
            output = temporary / f"{name}.py"
            subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "datamodel_code_generator",
                    "--input",
                    str(source),
                    "--input-file-type",
                    source_type,
                    "--output",
                    str(output),
                    "--output-model-type",
                    "pydantic_v2.BaseModel",
                    "--target-python-version",
                    "3.12",
                    "--disable-timestamp",
                    "--use-annotated",
                    "--field-constraints",
                    "--enum-field-as-literal",
                    "all",
                    "--use-union-operator",
                    "--use-standard-collections",
                    "--strict-nullable",
                    "--output-datetime-class",
                    "AwareDatetime",
                    "--strict-types",
                    "str",
                    "int",
                    "float",
                    "bool",
                    "--formatters",
                    "ruff-check",
                    "ruff-format",
                    "--no-allow-remote-refs",
                ],
                check=True,
                cwd=ROOT,
            )
            outputs.append((output, PACKAGE / "src/cic_contracts/generated" / output.name))

        typescript = temporary / "api.d.ts"
        subprocess.run(
            [
                "node",
                str(ROOT / "node_modules/openapi-typescript/bin/cli.js"),
                "docs/10_API_OPENAPI.yaml",
                "--output",
                str(typescript),
            ],
            check=True,
            cwd=ROOT,
        )
        outputs.append((typescript, PACKAGE / "types/api.d.ts"))
        drift = []
        for output, destination in outputs:
            content = output.read_text(encoding="utf-8")
            if args.check:
                if not destination.exists() or destination.read_text(encoding="utf-8") != content:
                    drift.append(str(destination.relative_to(ROOT)))
            else:
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_text(content, encoding="utf-8", newline="\n")
        if drift:
            raise SystemExit("Contract drift; run npm run contracts:generate:\n" + "\n".join(drift))
        print(f"Contracts {'checked' if args.check else 'generated'}: {len(outputs)} files")


if __name__ == "__main__":
    main()
