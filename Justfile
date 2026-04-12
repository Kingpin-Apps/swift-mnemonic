format:
    swiftformat --config .swiftformat Sources/ Tests/

lint: _make-test-results-dir
    swiftlint lint --reporter html > TestResults/lint.html || true

view-lint: lint
    open TestResults/lint.html

changelog:
    cz ch

bump: changelog
    cz bump

# Coverage targets

coverage: _make-coverage-dir
    swift test --enable-code-coverage
    xcrun llvm-cov export ./.build/arm64-apple-macosx/debug/SwiftMnemonicPackageTests.xctest/Contents/MacOS/SwiftMnemonicPackageTests \
        -instr-profile ./.build/arm64-apple-macosx/debug/codecov/default.profdata \
        --format=lcov > coverage/coverage-full.info
    grep -v '/Tests/' coverage/coverage-full.info > coverage/coverage.info || true
    echo "Coverage report generated at coverage/coverage.info"

coverage-report: coverage
    echo "\n=== COVERAGE REPORT FOR SOURCE FILES ==="
    xcrun llvm-cov report ./.build/arm64-apple-macosx/debug/SwiftMnemonicPackageTests.xctest/Contents/MacOS/SwiftMnemonicPackageTests \
        -instr-profile ./.build/arm64-apple-macosx/debug/codecov/default.profdata \
        Sources/SwiftMnemonic/

coverage-html: coverage
    #!/usr/bin/env bash
    set -euo pipefail
    which genhtml > /dev/null || (echo "Error: genhtml not found. Install lcov with: brew install lcov" && exit 1)
    genhtml coverage/coverage.info --output-directory coverage/html --title "SwiftMnemonic Coverage Report" --show-details --legend
    echo "HTML coverage report generated at coverage/html/index.html"
    echo "Open with: open coverage/html/index.html"

coverage-check: coverage
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking coverage threshold..."
    COVERAGE=$(xcrun llvm-cov report ./.build/arm64-apple-macosx/debug/SwiftMnemonicPackageTests.xctest/Contents/MacOS/SwiftMnemonicPackageTests \
        -instr-profile ./.build/arm64-apple-macosx/debug/codecov/default.profdata \
        Sources/SwiftMnemonic/ | tail -1 | awk '{print $10}' | sed 's/%//')
    COVERAGE_INT=$(echo "$COVERAGE" | cut -d'.' -f1)
    if [ "$COVERAGE_INT" -ge 90 ]; then
        echo "✅ Coverage $COVERAGE% meets minimum threshold (90%)"
    else
        echo "❌ Coverage $COVERAGE% is below minimum threshold (90%)"
        exit 1
    fi

[private]
_make-test-results-dir:
    mkdir -p TestResults

[private]
_make-coverage-dir:
    mkdir -p coverage
