"""Extract inspectable A121 SDK evidence using only Python's standard library.

This reads ELF32 little-endian binaries; it does not execute vendor code or
claim that extracted base images constitute a working sensor initialization.
"""
from __future__ import annotations

import hashlib
import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEST = Path(__file__).resolve().parents[1] / "generated"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class Elf32:
    def __init__(self, path: Path):
        self.path = path
        self.data = path.read_bytes()
        if self.data[:6] != b"\x7fELF\x01\x01":
            raise ValueError(f"Expected ELF32 little endian: {path}")
        hdr = struct.unpack_from("<16sHHIIIIIHHHHHH", self.data)
        if hdr[2] != 40 or hdr[11] != 40:
            raise ValueError("Expected ARM ELF with 40-byte section headers")
        self.sections = [struct.unpack_from("<10I", self.data, hdr[6] + i * hdr[11])
                         for i in range(hdr[12])]
        self.symbols = []
        for sec in self.sections:
            if sec[1] != 2:  # SHT_SYMTAB
                continue
            strings = self.sections[sec[6]]
            strdata = self.data[strings[4]:strings[4] + strings[5]]
            for offset in range(sec[4], sec[4] + sec[5], sec[9]):
                name, value, size, info, other, index = struct.unpack_from("<IIIBBH", self.data, offset)
                end = strdata.find(b"\0", name)
                name = strdata[name:end].decode("utf-8", errors="replace")
                self.symbols.append(dict(name=name, address=value, size=size,
                                         type=info & 15, section=index))

    def at(self, address: int, length: int) -> bytes:
        for sec in self.sections:
            if sec[1] != 8 and sec[3] <= address and address + length <= sec[3] + sec[5]:
                start = sec[4] + address - sec[3]
                result = self.data[start:start + length]
                if len(result) == length:
                    return result
        raise ValueError(f"Unmapped address: {address:#x}, length={length}")


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = {"warning": "Base images only: dynamic calibration/configuration patches remain required.",
                "sources": [], "images": [], "parameter_tables": [], "parameter_mappings": []}
    for stem in ["example_service", "example_detector_distance", "example_bring_up"]:
        elfpath = ROOT / "out" / (stem + ".elf")
        elf = Elf32(elfpath)
        manifest["sources"].append({"path": elfpath.relative_to(ROOT).as_posix(),
                                    "sha256": sha(elf.data),
                                    "version_strings": sorted({x.decode() for x in re.findall(rb"a121-v\d+\.\d+\.\d+", elf.data)})})
        for sym in elf.symbols:
            if sym["name"].startswith("acc_cpd_a121_meas_session_parameters_patch_table."):
                mapping = elf.at(sym["address"], sym["size"])
                manifest["parameter_mappings"].append(dict(sym, source=elfpath.relative_to(ROOT).as_posix(),
                    entries=[{"parameter_struct_byte_offset": 2 * i, "image_parameter_index": value}
                             for i, value in enumerate(mapping)],
                    interpretation="Listing: uint8 table maps consecutive uint16 fields to image parameter indices."))
            if sym["type"] != 1 or not sym["name"].startswith("acc_image_a121_"):
                continue
            data = elf.at(sym["address"], sym["size"])
            item = dict(sym, source=elfpath.relative_to(ROOT).as_posix(), sha256=sha(data))
            if "param_table" in sym["name"]:
                # Entries inferred from acc_confprogram_patch_offset: 8 bytes,
                # reference count at +2, pointer at +4. Preserve field +0 raw.
                if len(data) % 8:
                    raise ValueError("Parameter table not divisible by 8")
                entries = []
                for i, (field0, count, ptr) in enumerate(struct.iter_unpack("<HHI", data)):
                    refs = list(struct.unpack("<" + "I" * count, elf.at(ptr, 4 * count))) if count else []
                    entries.append({"index": i, "field0_raw": field0, "ref_count": count,
                                    "host_pointer_hex": f"0x{ptr:08X}",
                                    "references_hex": [f"0x{x:08X}" for x in refs],
                                    "references_decoded": [
                                        {"word32_offset": x & 0xFFFF, "type": (x >> 28) & 3,
                                         "bit_width_type0": (x >> 21) & 31,
                                         "bit_offset_type0": (x >> 16) & 31,
                                         "opcode_type1_or_2": (x >> 16) & 15} for x in refs]})
                item["entries"] = entries
                item["interpretation"] = "Reconstructed table layout; field0 semantics not assumed. Host pointers are NOT A121 addresses."
                manifest["parameter_tables"].append(item)
            else:
                if len(data) % 4:
                    raise ValueError("Image length not divisible by 4")
                words = [x[0] for x in struct.iter_unpack("<I", data)]
                item["words32"] = len(words)
                item["words16"] = 2 * len(words)
                # Export one copy only; keep cross-binary hashes in manifest.
                if stem == "example_service":
                    name = re.sub(r"\.\d+$", "", sym["name"])
                    for suffix, payload in [
                        (".host_le.bin", data),
                        (".words32.hex", "".join(f"{x:08X}\n" for x in words).encode()),
                        (".spi16.hex", "".join(f"{x >> 16:04X}\n{x & 65535:04X}\n" for x in words).encode()),
                    ]:
                        (DEST / (name + suffix)).write_bytes(payload)
                    item["export_prefix"] = name
                manifest["images"].append(item)
    index = []
    for stem in ["example_service", "example_detector_distance", "example_bring_up", "example_processing_peak_interpolation"]:
        listing = ROOT / "out" / (stem + ".list")
        lines = listing.read_text(encoding="utf-8", errors="replace").splitlines()
        manifest["sources"].append({"path": listing.relative_to(ROOT).as_posix(), "sha256": sha(listing.read_bytes())})
        for number, line in enumerate(lines, 1):
            match = re.fullmatch(r"([0-9a-fA-F]+) <([^>]+)>:", line)
            if match:
                index.append({"file": listing.relative_to(ROOT).as_posix(), "line": number,
                              "address": "0x" + match[1], "function": match[2]})
        # A browsing aid, not reconstructed compilable C: optimization interleaves
        # inline functions and some source lines may be missing or repeated.
        source_lines = [f"{i}: {line}" for i, line in enumerate(lines, 1)
                        if line.strip() and not re.match(r"^\s*[0-9a-fA-F]+:", line)]
        (DEST / (stem + ".source_fragments.txt")).write_text(
            "ANNOTATED LISTING FRAGMENTS - NOT COMPLETE OR COMPILABLE C\n" + "\n".join(source_lines) + "\n", encoding="utf-8")
    (DEST / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (DEST / "function_index.json").write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    for item in manifest["images"]:
        print(item["source"], item["name"], item["size"], item["sha256"])
    print("Parameter tables:", [(x["source"], x["name"], len(x["entries"])) for x in manifest["parameter_tables"]])
    print("Function index entries:", len(index))


if __name__ == "__main__":
    main()
