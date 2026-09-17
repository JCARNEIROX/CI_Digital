"""Reune os fontes atuais em duas abas para o EDA Playground, sem dependencias."""

import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verifica se as copias estao atualizadas.")
    args = parser.parse_args()
    output = Path(__file__).resolve().parent
    source = output.parent
    files = (source / "files.f").read_text(encoding="utf-8-sig").split()
    if len(files) != len(set(files)):
        raise SystemExit("files.f contem entradas duplicadas.")
    for name in files:
        if Path(name).name != name or not name.endswith(".sv"):
            raise SystemExit(f"Entrada nao suportada em files.f: {name}")
    required = {"ula_if.sv", "ula.sv", "top_tb.sv"}
    if not required.issubset(files):
        raise SystemExit("files.f deve listar ula_if.sv, ula.sv e top_tb.sv.")

    groups = {
        "design.sv": ["ula_if.sv", "ula.sv"],
        "testbench.sv": [name for name in files if name not in required] + ["top_tb.sv"],
    }
    stale = []
    for filename, inputs in groups.items():
        parts = [
            "// Gerado por preparar.py. Edite os fontes na pasta superior e gere novamente.\n",
            "`timescale 1ns/1ps\n",
        ]
        if filename == "testbench.sv":
            parts.append('`include "uvm_macros.svh"\nimport uvm_pkg::*;\n')
        for name in inputs:
            text = (source / name).read_text(encoding="utf-8-sig")
            parts.extend([f"\n// BEGIN SOURCE: {name}\n", text, f"\n// END SOURCE: {name}\n"])
        content = "".join(parts)
        target = output / filename
        if args.check:
            if not target.exists() or target.read_text(encoding="utf-8") != content:
                stale.append(filename)
        else:
            target.write_text(content, encoding="utf-8", newline="\n")
            print(f"Gerado {filename}: {len(inputs)} fontes")
    if stale:
        raise SystemExit("Copias desatualizadas: " + ", ".join(stale))
    if args.check:
        print(f"OK: {len(files)} fontes preservados nas duas abas.")


if __name__ == "__main__":
    main()
