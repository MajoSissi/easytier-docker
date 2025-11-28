#!/usr/bin/env python3
"""Generate Docker Hub README content from a compose file."""

import argparse
from pathlib import Path


def generate(compose_path: Path, output_path: Path) -> None:
    content = compose_path.read_text(encoding="utf-8")
    formatted = f"```yaml\n{content}\n```"
    output_path.write_text(formatted, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Render compose file to README snippet")
    parser.add_argument("compose", help="Path to docker-compose YAML")
    parser.add_argument("output", help="Path to write markdown snippet")
    args = parser.parse_args()

    compose_path = Path(args.compose)
    output_path = Path(args.output)
    if not compose_path.is_file():
        raise FileNotFoundError(f"Compose file not found: {compose_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    generate(compose_path, output_path)


if __name__ == "__main__":
    main()
