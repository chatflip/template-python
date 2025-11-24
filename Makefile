.PHONY: install lint format test

.DEFAULT_GOAL := help

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  install - Install dependencies"
	@echo "  format - Format code using ruff"
	@echo "  lint - Lint code using ruff and mypy"
	@echo "  test - Run tests using pytest"

install:
	uv sync --group dev --group lint --group test
	uv run pre-commit install

format:
	uv run --frozen ruff check --fix
	uv run --frozen ruff format

lint:
	uv run --frozen ruff check
	uv run --frozen ty check

test:
	uv run --frozen pytest ${TEST_FILES}
