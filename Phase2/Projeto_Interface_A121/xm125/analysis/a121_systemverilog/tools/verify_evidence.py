"""Check extraction consistency, not operation on physical A121 hardware."""
import hashlib
import json
import struct
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
ROOT = HERE.parents[1]
GEN = HERE / "generated"


def main():
    manifest = json.loads((GEN / "manifest.json").read_text(encoding="utf-8"))
    checks = []
    for source in manifest["sources"]:
        assert hashlib.sha256((ROOT / source["path"]).read_bytes()).hexdigest() == source["sha256"]
    checks.append("Source SHA256 hashes match manifest.")
    for item in manifest["images"]:
        name = item.get("export_prefix")
        if name is None:
            continue
        binary = (GEN / (name + ".host_le.bin")).read_bytes()
        w32 = [int(x, 16) for x in (GEN / (name + ".words32.hex")).read_text().split()]
        w16 = [int(x, 16) for x in (GEN / (name + ".spi16.hex")).read_text().split()]
        assert len(binary) == item["size"]
        assert binary == b"".join(struct.pack("<I", x) for x in w32)
        assert w32 == [(w16[i] << 16) | w16[i + 1] for i in range(0, len(w16), 2)]
        matches = [x for x in manifest["images"] if x["name"].rsplit(".", 1)[0] == name]
        assert len({x["sha256"] for x in matches}) == 1
        checks.append(f"{name}: binary/32-bit/16-bit round trip; same image in {len(matches)} firmware ELFs.")
    total_refs = 0
    for table in manifest["parameter_tables"]:
        stem = table["name"].split("_param_table")[0] + "."
        image = next(x for x in manifest["images"] if x["source"] == table["source"] and x["name"].startswith(stem))
        for entry in table["entries"]:
            assert len(entry["references_hex"]) == entry["ref_count"]
            for ref in entry["references_decoded"]:
                assert ref["word32_offset"] < image["words32"]
                assert ref["type"] in (0, 1, 2)
                if ref["type"] == 0:
                    assert 0 < ref["bit_width_type0"] <= 31
                    assert ref["bit_width_type0"] + ref["bit_offset_type0"] <= 32
                total_refs += 1
    checks.append(f"{total_refs} parameter references checked against image bounds and supported reference types.")
    for mapping in manifest["parameter_mappings"]:
        table = next(x for x in manifest["parameter_tables"] if x["source"] == mapping["source"] and "meas_session" in x["name"])
        assert len(mapping["entries"]) == 226
        assert all(0 <= x["image_parameter_index"] < len(table["entries"]) for x in mapping["entries"])
    checks.append("Measurement parameter mappings: 226 uint16 fields; indices within 242-entry table.")
    report = {"status": "PASS", "scope": "Static extraction consistency only; no hardware or complete RTL validation", "checks": checks}
    (GEN / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()

