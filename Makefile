.PHONY: help lint lint-yaml lint-all clean init validate

# Default target
help:
	@echo "Available targets:"
	@echo "  help           - Show this help message"
	@echo "  install-tools  - Install development dependencies"
	@echo "  lint           - Run all linters"
	@echo "  lint-yaml      - Lint YAML files"
	@echo "  check          - Run all checks (same as lint)"
	@echo "  clean          - Clean temporary files"

# Install development tools
init:
	@echo "Installing development tools..."
	@command -v yamllint >/dev/null 2>&1 || pip install yamllint
	@echo "Done."

# Lint YAML files
lint-yaml:
	@echo "Linting YAML files..."
	yamllint action.yml .github/

# Run all linters
lint: lint-yaml

# Alias for lint
validate: lint

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	rm -rf node_modules/
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -rf target/
	rm -f *.out
	rm -f *.test
	@echo "Done."
