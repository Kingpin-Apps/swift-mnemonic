
project:=SwiftMnemonic
comma:=,

format:
	swiftformat --config .swiftformat Sources/ Tests/

lint: make-test-results-dir
	- swiftlint lint --reporter html > TestResults/lint.html

view_lint: lint
	open TestResults/lint.html

changelog: ## Update changelog
	cz ch

bump: ## Bump version according to changelog
	cz bump

# Coverage targets
coverage: make-coverage-dir ## Run tests with coverage and generate coverage report
	swift test --enable-code-coverage
	xcrun llvm-cov export ./.build/arm64-apple-macosx/debug/SwiftMnemonicPackageTests.xctest/Contents/MacOS/SwiftMnemonicPackageTests -instr-profile ./.build/arm64-apple-macosx/debug/codecov/default.profdata --format=lcov > coverage/coverage-full.info
	@# Filter out test files from coverage report
	grep -v '/Tests/' coverage/coverage-full.info > coverage/coverage.info || true
	@echo "Coverage report generated at coverage/coverage.info"

coverage-report: coverage ## Generate coverage report and show summary (excluding test files)
	@echo "\n=== COVERAGE REPORT FOR SOURCE FILES ==="
	xcrun llvm-cov report ./.build/arm64-apple-macosx/debug/SwiftMnemonicPackageTests.xctest/Contents/MacOS/SwiftMnemonicPackageTests -instr-profile ./.build/arm64-apple-macosx/debug/codecov/default.profdata Sources/SwiftMnemonic/

coverage-html: coverage ## Generate HTML coverage report
	@which genhtml > /dev/null || (echo "Error: genhtml not found. Install lcov with: brew install lcov" && exit 1)
	genhtml coverage/coverage.info --output-directory coverage/html --title "SwiftMnemonic Coverage Report" --show-details --legend
	@echo "HTML coverage report generated at coverage/html/index.html"
	@echo "Open with: open coverage/html/index.html"

coverage-check: coverage ## Check if coverage meets minimum threshold (90%)
	@echo "Checking coverage threshold..."
	@COVERAGE=$$(xcrun llvm-cov report ./.build/arm64-apple-macosx/debug/SwiftMnemonicPackageTests.xctest/Contents/MacOS/SwiftMnemonicPackageTests -instr-profile ./.build/arm64-apple-macosx/debug/codecov/default.profdata Sources/SwiftMnemonic/ | tail -1 | awk '{print $$10}' | sed 's/%//'); \
	COVERAGE_INT=$$(echo "$$COVERAGE" | cut -d'.' -f1); \
	if [ "$$COVERAGE_INT" -ge 90 ]; then \
		echo "✅ Coverage $$COVERAGE% meets minimum threshold (90%)"; \
	else \
		echo "❌ Coverage $$COVERAGE% is below minimum threshold (90%)"; \
		exit 1; \
	fi

make-test-results-dir:
	mkdir -p TestResults

make-coverage-dir:
	mkdir -p coverage
