ifndef SOURCE_FILES
	export SOURCE_FILES:=src
endif

ifndef TEST_FILES
	export TEST_FILES:=tests
endif

.PHONY: lint format test

.DEFAULT_GOAL := help

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  format - Format code using ruff"
	@echo "  lint - Lint code using ruff and mypy"
	@echo "  test - Run tests using pytest"

format:
	mdformat README.md
	uv run ruff check $(SOURCE_FILES) $(TEST_FILES) --fix
	uv run ruff format $(SOURCE_FILES) $(TEST_FILES)

lint:
	uv run ruff check $(SOURCE_FILES) $(TEST_FILES)
	uv run mypy ${SOURCE_FILES} ${TEST_FILES}

test:
	uv run pytest ${TEST_FILES}
