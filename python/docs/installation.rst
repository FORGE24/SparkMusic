Installation
============

Requirements
------------

* Python 3.9 or newer
* :pypi:`requests` 2.28 or newer

The package itself has no cryptographic third-party dependency: AES, RSA and
hashing are implemented in :mod:`netease_api.crypto` using the standard library.

From the source tree
--------------------

.. code-block:: console

   $ pip install -r requirements.txt
   $ pip install .

Or, for development (editable install plus the optional test oracle):

.. code-block:: console

   $ pip install -r requirements-dev.txt
   $ pip install -e .

Wheel and source builds
-----------------------

A build helper produces and inspects a wheel:

.. code-block:: console

   $ python scripts/build_wheel.py
   $ python scripts/build_wheel.py --clean --sdist

The wheel is written to ``dist/`` and checked for missing or forbidden files
(tests, extraction artifacts, APK/DEX/native libraries). ``--sdist`` also
writes the API source distribution
``dist/netease_api_recovered-1.0.0.tar.gz``. To install either one:

.. code-block:: console

   $ pip install dist/netease_api_recovered-1.0.0-py3-none-any.whl
   $ pip install dist/netease_api_recovered-1.0.0.tar.gz   # builds from source

See :doc:`building` for the full build and documentation workflow.

Optional test dependency
------------------------

The test suite uses :pypi:`pycryptodome` as an independent AES oracle when it
is installed, and skips those checks otherwise. Install it with
``pip install -r requirements-dev.txt``.
