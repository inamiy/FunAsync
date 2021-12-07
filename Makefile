test-macOS:
	xcodebuild test -scheme FunAsync -destination 'platform=OS X' | xcpretty

test-iOS:
	xcodebuild test -scheme FunAsync -destination 'platform=iOS Simulator,name=iPhone 13 Pro' | xcpretty

test-watchOS:
	xcodebuild test -scheme FunAsync -destination 'platform=watchOS Simulator,name=Apple Watch Series 7 - 45mm' | xcpretty

test-tvOS:
	xcodebuild test -scheme FunAsync -destination 'platform=tvOS Simulator,name=Apple TV 4K' | xcpretty
