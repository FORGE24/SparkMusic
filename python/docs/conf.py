"""Sphinx configuration for the recovered NetEase API client docs."""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.abspath(".."))

from netease_api import __version__  # noqa: E402

project = "Netease API Recovered"
copyright = "2026, Netease API Recovered contributors"
author = "Netease API Recovered contributors"
release = __version__
version = __version__

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
    "sphinx.ext.viewcode",
    "sphinx.ext.extlinks",
]

extlinks = {
    "pypi": ("https://pypi.org/project/%s/", "pypi %s"),
}

autodoc_default_options = {
    "members": True,
    "undoc-members": False,
    "show-inheritance": True,
    "member-order": "bysource",
}
autodoc_typehints = "signature"
autodoc_preserve_defaults = True
napoleon_google_docstring = True
napoleon_numpy_docstring = False
napoleon_include_init_with_doc = False

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

html_theme = "alabaster"
html_title = f"{project} {release}"
html_short_title = project
html_static_path: list[str] = []
pygments_style = "sphinx"

# Keep builds fully offline and warning-clean.
nitpicky = False
suppress_warnings = ["ref.myst"]
