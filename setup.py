#!/usr/bin/env python3
"""Setup script for TextForensics package"""

from pathlib import Path

from setuptools import find_packages, setup

# Read README for long description
this_directory = Path(__file__).parent
try:
    long_description = (this_directory / "README.md").read_text()
except FileNotFoundError:
    long_description = "GPU-optimized text forensics ML pipeline"


# Helper function to read requirements files
def read_requirements(filename):
    """Read requirements from requirements/ directory"""
    requirements_path = this_directory / "requirements" / filename
    if requirements_path.exists():
        return requirements_path.read_text().strip().split("\n")
    return []


setup(
    # Package metadata
    name="textforensics",
    version="0.1.0",
    author="Surajit Dutta",
    author_email="hello@surajit.de",
    description="GPU-optimized text forensics ML pipeline",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/surajroland/textforensics",
    # Package structure
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    # Classification
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Science/Research",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.12",
        "Operating System :: POSIX :: Linux",
    ],
    # Requirements
    python_requires=">=3.12",
    install_requires=read_requirements("base.txt"),
    extras_require={
        "dev": read_requirements("dev.txt"),
        "training": read_requirements("training.txt"),
        "api": read_requirements("api.txt"),
    },
    # CLI entry points
    entry_points={
        "console_scripts": [
            "textforensics=textforensics.cli:main",
        ],
    },
    # Package configuration
    include_package_data=True,
    zip_safe=False,
)
