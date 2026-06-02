# Makefile for QXPal Audio Optimization Framework

.PHONY: all install uninstall test lint clean

all:
	@echo "QXPal Audio Optimization Framework"
	@echo "Available commands:"
	@echo "  make install     - Run the install script (requires sudo)"
	@echo "  make uninstall   - Run the uninstall script (requires sudo)"
	@echo "  make test        - Run all unit tests"
	@echo "  make lint        - Run shellcheck on all scripts"
	@echo "  make clean       - Clean temporary and test files"

install:
	@echo "Installing QXPal..."
	sudo ./install.sh

uninstall:
	@echo "Uninstalling QXPal..."
	sudo ./uninstall.sh

test:
	@echo "Running test suite..."
	@bash tests/test_detection.sh
	@bash tests/test_profiles.sh
	@bash tests/test_install.sh

lint:
	@echo "Running shellcheck on scripts..."
	@shellcheck qxpal install.sh uninstall.sh
	@shellcheck scripts/*.sh
	@shellcheck tests/*.sh

clean:
	@echo "Cleaning workspace..."
	find . -type f -name "*~" -delete
	find . -type f -name "*.log" -delete
	rm -rf test_root/
