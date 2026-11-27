from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "src"
ORDER = [
    "00_lib.lua",
    "01_icons.lua",
    "02_reflection.lua",
    "03_ui.lua",
    "04_explorer.lua",
    "05_properties.lua",
    "06_output.lua",
    "07_launcher.lua",
    "08_consolebypass.lua",
    "09_notepad.lua",
    "10_bypass.lua",
    "11_ussi.lua",
    "12_modelviewer.lua",
    "14_filesystem.lua",
    "99_boot.lua",
]


def main() -> None:
    chunks = []
    for name in ORDER:
        path = SRC / name
        if not path.exists():
            raise SystemExit(f"missing source module: {path}")
        chunks.append(path.read_text(encoding="utf-8").rstrip())

    output = "\n\n".join(chunks)
    (ROOT / "main.lua").write_text(output, encoding="utf-8")
    lines = output.count("\n") + 1
    print(f"built main.lua ({lines:,} lines, {len(output):,} bytes)")


if __name__ == "__main__":
    main()
