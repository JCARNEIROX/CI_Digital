"""Recover type/enum evidence from DWARF; requires locally installed pyelftools."""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "_vendor"))
from elftools.elf.elffile import ELFFile

ROOT = HERE.parents[2]


def name(die):
    attr = die.attributes.get("DW_AT_name")
    return attr.value.decode(errors="replace") if attr else None


def main():
    records = []
    with (ROOT / "out/example_service.elf").open("rb") as stream:
        dwarf = ELFFile(stream).get_dwarf_info()
        for cu in dwarf.iter_CUs():
            for die in cu.iter_DIEs():
                if die.tag not in ("DW_TAG_enumeration_type", "DW_TAG_structure_type", "DW_TAG_typedef"):
                    continue
                n = name(die)
                target = die
                if die.tag == "DW_TAG_typedef":
                    if "DW_AT_type" not in die.attributes:
                        continue
                    target = die.get_DIE_from_attribute("DW_AT_type")
                    if target.tag not in ("DW_TAG_enumeration_type", "DW_TAG_structure_type"):
                        continue
                children = list(target.iter_children())
                names = [name(child) or "" for child in children]
                searchable = " ".join([n or ""] + names).lower()
                if not any(s in searchable for s in ("a121", "calibration", "confprogram", "buffer_", "payload", "sensor_spi")):
                    continue
                fields = []
                for child in children:
                    item = {"name": name(child), "tag": child.tag}
                    for key in ("DW_AT_const_value", "DW_AT_data_member_location", "DW_AT_byte_size"):
                        if key in child.attributes:
                            item[key.removeprefix("DW_AT_")] = child.attributes[key].value
                    fields.append(item)
                records.append({"name": n, "tag": target.tag, "die_offset": die.offset,
                                "byte_size": target.attributes["DW_AT_byte_size"].value if "DW_AT_byte_size" in target.attributes else None,
                                "fields": fields})
    output = HERE.parent / "generated/debug_types.json"
    output.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
    for record in records:
        if record["name"]:
            print(record["name"], record["tag"], len(record["fields"]))
    print("Records:", len(records))


if __name__ == "__main__":
    main()
