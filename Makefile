SHELL := /bin/bash
PROJECT := project
PYTHON_VERSION := 3.8.0
VENV = ${PROJECT}-${PYTHON_VERSION}
VENV_DIR = $(shell pyenv root)/versions/${VENV}
PYTHON = ${VENV_DIR}/bin/python
PYTHONHASHSEED := 0
GIT_TREE_STATE := $(shell git status -s)
GIT_BRANCH := $(shell git branch | grep \* | cut -d ' ' -f2)
VERSION_NUMBER := $(shell $(PYTHON) setup.py --version)
DEFAULT_GOAL: help  # Target to execute when calling `make` without a target.

# Formatting for echos.
ccend=$(shell tput sgr0)
ccbold=$(shell tput bold)
ccgreen=$(shell tput setaf 2)
ccso=$(shell tput smso)

# Add virtual env to path, so that everything gets executed inside the virtual env.
export PATH := ${VENV_DIR}/bin:${PATH}

mac: ##@installation >> install pyenv and pyenv-virtualenv on MacOS
	brew update
	brew install pyenv pyenv-virtualenv
	brew install pre-commit

install_user: venv requirements.txt ##@installation >> create user virtual environment based on `requirements.txt`
	@echo "$(ccso)--> Install packages $(ccend)"
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt

install_dev: venv requirements.txt ##@installation >> create development virtual environment based on `setup.py` dev packages
	@echo "$(ccso)--> Install packages $(ccend)"
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -e ".[dev]"
	@echo "$(ccso)--> Activate pre-commit hooks $(ccend)"
	pre-commit install

venv: $(VENV_DIR)

$(VENV_DIR):
	@echo "$(ccso)--> Set up virtual environment $(ccend)"
	python3 -m pip install --upgrade pip
	pyenv virtualenv ${PYTHON_VERSION} ${VENV}
	echo ${VENV} > .python-version

check: install_dev check_code_compliance run_tests_local check_branch_matches_version check_git_uptodate ##@development >> check if package is ready for release

check_code_compliance: flake black isort ##@development >> check if `ods_pythia` complies with flake8, black & isort formatting

flake:
	@echo "$(ccso)--> Check flake8 compliance of ods_pythia $(ccend)"
	flake8 ${PROJECT}/ scripts/ setup.py

black:
	@echo "$(ccso)--> Check black compliance of ods_pythia $(ccend)"
	black ${PROJECT}/ scripts/ setup.py

isort:
	@echo "$(ccso)--> Check isort compliance of ods_pythia $(ccend)"
	isort -rc ${PROJECT}/ scripts/ setup.py

run_tests_local: install_dev clean_tests ##@development >> run tests inside virtual environment
	@echo "$(ccso)--> Run tests $(ccend)"
	export PYTHONHASHSEED=$(PYTHONHASHSEED)
	pytest --cov=${PROJECT}/ --cov-report=term-missing --disable-pytest-warnings

.ONESHELL:
check_branch_matches_version:
ifeq ($(GIT_BRANCH), release/v$(VERSION_NUMBER))
    @echo "$(ccso)--> Check if branch name matches ods_pythia version $(ccend)"
	echo -e Git branch: $(GIT_BRANCH) and version number: release/v$(VERSION_NUMBER) are equal
	exit 0
else
	@echo "$(ccso)--> Check if branch name matches ods_pythia version $(ccend)"
	echo -e Git branch: $(GIT_BRANCH) and version number: release/v$(VERSION_NUMBER) are not equal
	exit 1
endif

check_git_uptodate:
ifeq ($(GIT_TREE_STATE),)
	@echo "$(ccso)--> Check if Git tree is clean $(ccend)"
	@echo Working directory is clean
	exit 0
else
	@echo "$(ccso)--> Check if Git tree is clean $(ccend)"
	@echo There are uncommitted changes
	exit 1
endif

build: clean_build
	@echo "$(ccso)--> Build project $(ccend)"
	python setup.py sdist bdist_wheel;

clean_all: clean_build clean_tests clean_venv ##@clean >> clean all

clean_venv: ##@clean >> remove all environment-related files
	@echo ""
	@echo "$(ccso)--> Removing virtual environment $(ccend)"
	pyenv virtualenv-delete --force ${VENV}
	rm .python-version

clean_tests: ##@clean >> remove all testing-related files
	@echo "$(ccso)--> Clean tests $(ccend)"
	rm -rf dist build .eggs *.egg-info test-reports
	find . -name .pytest_cache -type d -exec rm -rf {} +
	find . -name __pycache__ -type d -exec rm -rf {} +

clean_build: ##@clean >> remove all build-related files
	@echo "$(ccso)--> Clean build $(ccend)"
	rm -rf dist build .eggs *.egg-info
	find . -name __pycache__ -type d -exec rm -rf {} +


# Add help text after each target name starting with `##`
# A category can be added with @category
HELP_FUN = \
	%help; \
	while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\_\-\$\(]+)\s*:.*\#\#(?:@([a-zA-Z\-\)]+))?\s(.*)$$/ }; \
	print "usage: make [target]\n\n"; \
	for (sort keys %help) { \
	print "${WHITE}$$_:${RESET}\n"; \
	for (@{$$help{$$_}}) { \
	$$sep = " " x (32 - length $$_->[0]); \
	print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
	}; \
	print "\n"; }

help: ##@other >> show this help
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)
	@echo ""
	@echo "Note: to activate the environment in your local shell type:"
	@echo "   $$ pyenv shell $(VENV)"
