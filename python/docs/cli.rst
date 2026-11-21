Command line
============

The package installs a ``netease-api`` entry point and also runs as a module:

.. code-block:: console

   $ python -m netease_api --version
   $ python -m netease_api routes comment --group comment --params
   $ python -m netease_api routes search --inferred --json
   $ python -m netease_api call song/detail "ids=[347230]"
   $ python -m netease_api call v6/playlist/detail id=3778678 n=30
   $ python -m netease_api search 海阔天空 --type song --limit 5
   $ python -m netease_api song 347230 --url --level lossless
   $ python -m netease_api song 347230 --lyric
   $ python -m netease_api playlist 3778678
   $ python -m netease_api user 123456 --playlists
   $ python -m netease_api login cellphone --phone 13800000000 \
         --password secret --save-cookies cookies.json

Shared options
--------------

``--mode {eapi,weapi,api,linuxapi}``
   Transport mode (default ``eapi``).
``--cookie``
   Raw cookie string; defaults to ``NETEASE_COOKIE``.
``--cookie-file``
   JSON cookie file written by ``save_cookies``.
``--timeout``
   Request timeout in seconds.
``--strict``
   Raise ``ApiError`` when the JSON ``code`` is not 200.

Parameter values in ``call`` are auto-typed: integers, floats, booleans,
``null``, JSON arrays/objects, or ``@file`` to read a value from disk.
``--param-file`` merges a JSON object into the parameters.

.. automodule:: netease_api.cli
   :members: main, build_parser, parse_params, parse_value, emit
