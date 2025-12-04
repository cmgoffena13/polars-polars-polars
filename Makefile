format: lint
	uv run -- ruff format

lint:
	uv run -- ruff check --fix

test:
	uv run -- pytest -v -n auto

install:
	uv sync --frozen --compile-bytecode

setup:
	uv sync --frozen --compile-bytecode
	uv run -- pre-commit install --install-hooks

upgrade:
	uv sync --upgrade --all-extras

run:
	uv run -- python -m main