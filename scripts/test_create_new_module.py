"""Verificações do gerador; execute python -m unittest discover -s scripts."""

import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import create_new_module as generator


class CreateModuleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="uvm_generator_test_")
        self.root = Path(self.temporary.name).resolve()
        self.assertTrue(self.root.is_relative_to(Path(tempfile.gettempdir()).resolve()))
        self.addCleanup(self.temporary.cleanup)

    def test_generated_files_and_compilation_dependencies(self):
        module, _ = generator.create_module(self.root / "projeto com espaços", "adder")
        self.assertTrue((module / "resultados").is_dir())
        components = (
            "if", "pkg", "sequence_item", "sequence", "driver", "monitor",
            "agent", "scoreboard", "env", "test",
        )
        expected = {f"tb/adder_{name}.sv" for name in components}
        expected.update({"rtl/adder.sv", "tb/tb_top.sv", "filelist.f", "README.md"})
        actual = {p.relative_to(module).as_posix() for p in module.rglob("*") if p.is_file()}
        self.assertEqual(actual, expected)
        for name in actual:
            self.assertNotIn("@MODULE@", (module / name).read_text(encoding="utf-8"))

        filelist = (module / "filelist.f").read_text(encoding="utf-8")
        sources = [line for line in filelist.splitlines() if line.endswith(".sv")]
        self.assertEqual(sources, [
            "rtl/adder.sv", "tb/adder_if.sv", "tb/adder_pkg.sv", "tb/tb_top.sv",
        ])
        package = (module / "tb/adder_pkg.sv").read_text(encoding="utf-8")
        includes = re.findall(r'`include "([^"]+\.sv)"', package)
        self.assertEqual(len(includes), len(set(includes)))
        # Cada fonte pertence ao filelist OU aos includes do pacote, uma única vez.
        self.assertEqual(
            set(sources) | {f"tb/{name}" for name in includes},
            {name for name in expected if name.endswith(".sv")},
        )
        self.assertFalse(set(sources) & {f"tb/{name}" for name in includes})

    def test_existing_work_is_never_overwritten(self):
        module, _ = generator.create_module(self.root, "adder")
        rtl = module / "rtl/adder.sv"
        rtl.write_text("// RTL editado pelo usuário\n", encoding="utf-8")
        before = {p: p.read_bytes() for p in module.rglob("*") if p.is_file()}
        with self.assertRaises(FileExistsError):
            generator.create_module(self.root, "adder")
        self.assertEqual(before, {p: p.read_bytes() for p in module.rglob("*") if p.is_file()})

    def test_cli_from_another_directory_and_invalid_names(self):
        script = str(Path(generator.__file__).resolve())
        with patch.object(generator, "PROJECT_ROOT", self.root):
            module, _ = generator.create_module("projeto relativo", "counter_2")
        self.assertEqual(module, self.root / "projeto relativo/modules/counter_2")
        result = subprocess.run(
            [sys.executable, script, str(self.root / "cli"), "counter_2"],
            cwd=self.root, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.root / "cli/modules/counter_2/tb/counter_2_pkg.sv").is_file())
        for invalid in ("9adder", "../escape", "a/b", "a\\b", "bad-name", "tb_top"):
            with self.subTest(name=invalid):
                result = subprocess.run(
                    [sys.executable, script, str(self.root / "invalid"), invalid],
                    cwd=self.root, capture_output=True,
                )
                self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "invalid").exists())

    def test_script_runs_without_companion_files(self):
        isolated_script = self.root / "create_new_module.py"
        shutil.copyfile(generator.__file__, isolated_script)
        result = subprocess.run(
            [sys.executable, str(isolated_script), str(self.root / "standalone"), "adder"],
            cwd=self.root, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.root / "standalone/modules/adder/filelist.f").is_file())


if __name__ == "__main__":
    unittest.main()
