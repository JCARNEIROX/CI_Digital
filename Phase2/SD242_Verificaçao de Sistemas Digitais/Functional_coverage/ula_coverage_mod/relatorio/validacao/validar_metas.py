"""Audita testemunhas para os bins atuais e simula o RTL extraido com Icarus.

Nao executa UVM/covergroups nem substitui a medicao de cobertura no Xcelium.
"""

import csv
import itertools
from pathlib import Path
import re
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
MASK32 = (1 << 32) - 1
MASK64 = (1 << 64) - 1


def main():
    item = (ROOT / "ula_item.sv").read_text(encoding="utf-8-sig")
    sequence = (ROOT / "ula_sequence.sv").read_text(encoding="utf-8-sig")
    coverage = (ROOT / "ula_coverage.sv").read_text(encoding="utf-8-sig")
    operations = dict((name, int(bits, 2)) for name, bits in
                      re.findall(r"localparam\s+(OP_\w+)\s*=\s*3'b([01]+)", item))
    assert list(operations.values()) == list(range(7)), operations

    def number(text):
        text = text.strip()
        if text.startswith("ula_item::"):
            return operations[text.split("::")[1]]
        match = re.fullmatch(r"\d+'([bdh])([0-9a-fA-F]+)", text)
        return int(match[2], {"b": 2, "d": 10, "h": 16}[match[1]]) if match else int(text)

    # O plano replica os loops dirigidos simples; as expressoes sao verificadas.
    array = re.search(r"values\[(\d+)\]\s*=\s*'\{(.*?)\};", sequence, re.S)
    values = [number(x) for x in array[2].split(",")]
    assert len(values) == int(array[1])
    assert "op <= ula_item::OP_OR" in sequence
    assert "send_directed(op[2:0], values[i], values[j]);" in sequence
    assert "send_directed(ula_item::OP_NOT, values[i], 32'd0);" in sequence
    vectors = [(op, a, b) for op in range(operations["OP_ADD"], operations["OP_OR"] + 1)
               for a in values for b in values]
    vectors += [(operations["OP_NOT"], a, 0) for a in values]
    for op, a, b in re.findall(r"send_directed\(ula_item::(OP_\w+),\s*(\d+'[dh][0-9a-fA-F]+),\s*(\d+'[dh][0-9a-fA-F]+)\);", sequence):
        vectors.append((operations[op], number(a), number(b)))

    # Extrai nomes e intervalos dos bins explicitamente declarados no coverage.
    names = ["opr_cp", "a_val", "b_val", "result_cp", "carry_cp", "zero_cp",
             "sub_order_cp", "div_denominator_cp", "alternating_pair_cp"]
    bins = {}
    for name in names:
        block = coverage.split(name + " : coverpoint", 1)[1].split("\n        }", 1)[0]
        bins[name] = {}
        for label, body in re.findall(r"\bbins\s+(\w+)\s*=\s*\{([^}]+)\}", block):
            intervals = []
            for token in body.split(","):
                token = token.strip()
                if token.startswith("["):
                    lower, upper = map(number, token[1:-1].split(":"))
                else:
                    lower = upper = number(token)
                intervals.append((lower, upper))
            bins[name][label] = intervals
        assert bins[name], name

    for name, width in [("a_val", 32), ("b_val", 32), ("result_cp", 64)]:
        intervals = sorted(interval for ranges in bins[name].values() for interval in ranges)
        end = -1
        for lower, upper in intervals:
            assert lower == end + 1 and lower <= upper, (name, lower, upper)
            end = upper
        assert end == (1 << width) - 1

    def classify(name, value):
        hits = [label for label, ranges in bins[name].items()
                if any(lower <= value <= upper for lower, upper in ranges)]
        assert len(hits) <= 1, (name, value, hits)
        return hits[0] if hits else None

    # As exclusoes abaixo correspondem aos ignore_bins revisados no SV.
    compact = re.sub(r"\s+", "", coverage)
    assert "ignore_binsunused_b=binsof(opr_cp.not_op);" in compact
    assert "ignore_binslogical_carry=(binsof(opr_cp)intersect{ula_item::OP_AND,ula_item::OP_OR,ula_item::OP_NOT})&&binsof(carry_cp.carry);" in compact
    assert "opr_zero_cross:crossopr_cp,zero_cp;" in compact
    goals = {name: set(labels) for name, labels in bins.items()}
    goals["opr_a_cross"] = set(itertools.product(bins["opr_cp"], bins["a_val"]))
    goals["opr_b_cross"] = {(op, b) for op in bins["opr_cp"] for b in bins["b_val"] if op != "not_op"}
    goals["logical_pattern_cross"] = set(itertools.product(["and_op", "or_op"], bins["alternating_pair_cp"]))
    goals["opr_carry_cross"] = {(op, carry) for op in bins["opr_cp"] for carry in bins["carry_cp"]
                               if not (op in ["and_op", "or_op", "not_op"] and carry == "carry")}
    goals["opr_zero_cross"] = set(itertools.product(bins["opr_cp"], bins["zero_cp"]))
    declared_metrics = set(re.findall(r"(\w+)\s*:\s*(?:coverpoint|cross)\b", coverage))
    assert declared_metrics == set(goals), "Atualize a auditoria para as novas metricas"

    witnesses = {name: {} for name in goals}
    rows = []
    for op, a, b in vectors:
        if op == operations["OP_ADD"]:
            result, carry = a + b, int(a + b > MASK32)
        elif op == operations["OP_SUB"]:
            result, carry = (a - b) & MASK64, int(a < b)
        elif op == operations["OP_MUL"]:
            result, carry = a * b, int(a * b > MASK32)
        elif op == operations["OP_DIV"]:
            result, carry = (a // b, 0) if b else (0, 1)
        elif op == operations["OP_AND"]:
            result, carry = a & b, 0
        elif op == operations["OP_OR"]:
            result, carry = a | b, 0
        else:
            result, carry = a ^ MASK32, 0
        zero = int(result == 0)
        row = (op, a, b, result, carry, zero)
        rows.append(row)
        hits = {name: classify(name, value) for name, value in
                [("opr_cp", op), ("a_val", a), ("b_val", b), ("result_cp", result),
                 ("carry_cp", carry), ("zero_cp", zero)]}
        if op == operations["OP_SUB"]:
            hits["sub_order_cp"] = classify("sub_order_cp", 0 if a < b else 1 if a == b else 2)
        if op == operations["OP_DIV"]:
            hits["div_denominator_cp"] = classify("div_denominator_cp", b)
        if op in [operations["OP_AND"], operations["OP_OR"]]:
            pair = classify("alternating_pair_cp", (a << 32) | b)
            if pair:
                hits["alternating_pair_cp"] = pair
                hits["logical_pattern_cross"] = (hits["opr_cp"], pair)
        hits["opr_a_cross"] = (hits["opr_cp"], hits["a_val"])
        if op != operations["OP_NOT"]:
            hits["opr_b_cross"] = (hits["opr_cp"], hits["b_val"])
        hits["opr_carry_cross"] = (hits["opr_cp"], hits["carry_cp"])
        hits["opr_zero_cross"] = (hits["opr_cp"], hits["zero_cp"])
        for name, label in hits.items():
            assert label in goals[name], (name, label)
            witnesses[name].setdefault(label, row)

    summary = [f"Plano dirigido: {len(rows)} vetores. Auditoria de metas; nao e medicao UVM."]
    with (HERE / "metas_dirigidas.csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["metric", "bin", "opr", "a_hex", "b_hex", "result_hex", "carry", "zero"])
        for name, targets in goals.items():
            missing = targets - witnesses[name].keys()
            assert not missing, (name, missing)
            summary.append(f"{name}: {len(witnesses[name])}/{len(targets)} metas com testemunha")
            for label in sorted(targets):
                op, a, b, result, carry, zero = witnesses[name][label]
                writer.writerow([name, "/".join(label) if isinstance(label, tuple) else label,
                                 op, f"{a:08X}", f"{b:08X}", f"{result:016X}", carry, zero])

    # Icarus nao executa este ambiente UVM. Extraimos o corpo RTL e substituimos
    # a porta de interface por sinais locais para conferir cada vetor/flag.
    dut = (ROOT / "ula.sv").read_text(encoding="utf-8-sig")
    dut = dut[dut.index("    // Operation codes"):dut.rindex("endmodule")].replace("u_if.", "")
    with tempfile.TemporaryDirectory(prefix="ula_metas_") as folder:
        work = Path(folder)
        packed = [(op << 130) | (a << 98) | (b << 66) | (result << 2) | (carry << 1) | zero
                  for op, a, b, result, carry, zero in rows]
        (work / "vectors.mem").write_text("\n".join(f"{value:034x}" for value in packed) + "\n")
        bench = """`timescale 1ns/1ps
module validation_top;
logic clk = 0;
logic rst_n = 0;
logic [31:0] a, b;
logic [2:0] opr;
logic [63:0] result;
logic carry_o, zero;
always #5 clk = ~clk;
""" + dut + f"""
logic [132:0] vectors[0:{len(rows)-1}];
logic [63:0] expected_result;
logic expected_carry, expected_zero;
initial begin
    $readmemh("vectors.mem", vectors);
    #2 rst_n = 1;
    for (int i = 0; i < {len(rows)}; i++) begin
        @(negedge clk);
        {{opr,a,b,expected_result,expected_carry,expected_zero}} = vectors[i];
        @(posedge clk);
        @(negedge clk);
        if ({{result,carry_o,zero}} !== {{expected_result,expected_carry,expected_zero}})
            $fatal(1, "Divergencia no vetor %0d opr=%0d a=%h b=%h", i, opr, a, b);
    end
    $display("RTL: {len(rows)} vetores aprovados; resultado, carry e zero conferidos.");
    $finish;
end
endmodule
"""
        (work / "check.sv").write_text(bench, encoding="utf-8")
        compiled = subprocess.run(["iverilog", "-g2012", "-s", "validation_top", "-o", "check.vvp", "check.sv"],
                                  cwd=work, capture_output=True, text=True)
        if compiled.returncode:
            raise SystemExit(compiled.stderr)
        simulated = subprocess.run(["vvp", "check.vvp"], cwd=work, capture_output=True, text=True)
        if simulated.returncode:
            raise SystemExit(simulated.stdout + simulated.stderr)
        summary.append(simulated.stdout.splitlines()[0])
    summary.append("Pendente: compilacao UVM, sorteio dos cinco tipos e cobertura nativa no Xcelium.")
    text = "\n".join(summary) + "\n"
    (HERE / "resultado_metas.txt").write_text(text, encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
