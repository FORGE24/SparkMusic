Netease API Recovered
=====================

A class-style Python client for the NetEase Cloud Music API recovered from the
Android 9.6.30 APK. The catalog covers **1,293 routes in 150 groups**; the base
client exposes **334 methods**, and any catalog route can be called directly.

.. code-block:: python

   from netease_api import NeteaseClient

   client = NeteaseClient()
   client.search_songs("海阔天空", limit=10)
   client.song_url(347230, level="lossless")

This documentation covers installation, authentication, the client API,
transport and encryption details, the command line, and the full route
catalog. For the reverse-engineering narrative (DEX analysis method, recovered
request architecture, native encryption findings and limitations), see the
``API.md`` file in the repository root.

.. toctree::
   :maxdepth: 2
   :caption: Contents

   installation
   usage
   authentication
   cli
   api/index
   route_catalog
   recovery
   building

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
