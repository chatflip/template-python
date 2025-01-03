#!/bin/bash
set -eux
uv tool install ruff@0.8.5
uv tool install mypy@1.14.1
uv tool install pre-commit
