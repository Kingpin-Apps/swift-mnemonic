
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
