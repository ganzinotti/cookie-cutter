import os
from setuptools import setup, find_packages
from project import settings


def convert_requirements_to_list(fname):
    with open(os.path.join(os.path.dirname(__file__), fname), "r") as f:
        packages = [line.strip("\n") for line in f.readlines()]

    return packages


base_packages = convert_requirements_to_list("requirements.txt")
docs_packages = convert_requirements_to_list("requirements_docs.txt")
dev_packages = convert_requirements_to_list("requirements_dev.txt")

setup(
    name=settings.PACKAGE_NAME,
    version=settings.PACKAGE_VERSION,
    description=settings.PACKAGE_DESCRIPTION,
    author=settings.PACKAGE_AUTHOR,
    url=settings.PACKAGE_URL,
    packages=find_packages(),
    setup_requires=["pytest-runner"],
    install_requires=base_packages,
    extras_require={"docs": docs_packages, "dev": dev_packages},
)
