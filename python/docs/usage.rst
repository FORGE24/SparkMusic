Using the client
================

Creating a client
-----------------

.. code-block:: python

   from netease_api import NeteaseClient

   client = NeteaseClient()                 # anonymous, eapi transport
   client = NeteaseClient(mode="weapi")     # alternate transport
   client = NeteaseClient.from_cookie_file("cookies.json")
   client = NeteaseClient.from_env()        # NETEASE_COOKIE / NETEASE_MUSIC_U

``NeteaseClient`` combines all 25 resource mixins (login, user, song, album,
artist, MV, playlist, search, comment, DJ, radio, recommendations, events,
mlog, topic, messages, cloud, VIP, settings, reports, feedback, listen
together and the "mine" tab). See :doc:`api/index` for every class and method.

Common calls
------------

.. code-block:: python

   client.search_songs("海阔天空", limit=10)
   client.song_detail(347230)
   client.song_url(347230, level="lossless", encode_type="flac")
   client.song_lyric(347230)
   client.album_detail(32311)
   client.artist_detail(6452)
   client.playlist_detail(3778678, track_limit=30)
   client.comment_music(347230)
   client.recommend_songs()
   client.user_playlists(123456)

Every method returns the decoded JSON response. NetEase uses non-200 ``code``
values for partial successes too, so responses are returned rather than raised
unless strict mode is enabled.

Comments use the standard thread ids, built for you:

.. code-block:: python

   client.comment_music(347230)        # R_SO_4_347230
   client.thread_id("playlist", 1)     # R_PL_2_1
   client.comment_floor("R_SO_4_347230", parent_comment_id=2)

Calling any catalog route
-------------------------

All 1,293 recovered routes are reachable, including ones without a typed
method:

.. code-block:: python

   client.call("v6/playlist/detail", id=3778678, n=30, s=0, v=1)
   client.call("mlog/detail", id="a_mlog_id")
   client.call("event/get/123456", limit=10)

Underscore-prefixed keywords control the request rather than being sent as
parameters:

.. code-block:: python

   client.call("user/playlist", uid=123,
               _mode="weapi", _method="GET", _timeout=5,
               _headers={"X-Trace": "1"})

``client.raw()`` is an alias, and ``client.request`` also points at
:meth:`NeteaseClient.call`.

Looking routes up
-----------------

.. code-block:: python

   from netease_api import routes

   routes.get("song/detail")       # -> v3/song/detail
   routes.find("comment")          # substring search
   routes.summary()                # counts per group
   routes.ENDPOINTS["mlog/detail"].params

``get()`` accepts leading slashes, transport prefixes and query strings, and
tries ``v1/``–``v9/`` prefixed spellings. It never fuzzy-matches a suffix, so a
typo raises ``KeyError`` instead of returning the wrong endpoint.

Configuration
-------------

.. code-block:: python

   client = NeteaseClient(
       mode="eapi",                     # eapi | weapi | api | linuxapi
       timeout=15.0,
       retries=2,
       proxies={"https": "http://127.0.0.1:8080"},
       headers={"X-My-Header": "1"},
       inject_defaults=True,
       raise_on_api_error=False,
       verify=True,
   )

Custom base URLs:

.. code-block:: python

   NeteaseClient(base_url="https://interface.music.163.com/eapi/")
   NeteaseClient(base_urls={"eapi": "https://example.test/eapi/"})

``client.config`` exposes the :class:`~netease_api.transport.TransportConfig`,
and ``client.mode``, ``client.cookies`` and ``client.csrf_token`` are
convenience accessors.

Batch calls
-----------

.. code-block:: python

   results = client.batch(
       [
           ("v6/playlist/detail", {"id": 3778678}),
           {"route": "song/detail", "params": {"ids": "347230"}},
       ],
       workers=4,
   )
   # [{"route": ..., "ok": True, "data": ...}, ...]

Parallel batches use one session per worker and are intended for independent
reads; cookie changes from concurrent calls are not merged back.

Errors
------

.. code-block:: python

   from netease_api import (
       NeteaseError, TransportError, ApiError,
       NativeEncryptionUnavailable, UnsupportedMode,
   )

   try:
       data = client.song_detail(1)
   except TransportError as exc:
       print(exc.status, exc.payload)

* :class:`~netease_api.errors.TransportError` — network failure or HTTP >= 400.
* :class:`~netease_api.errors.ApiError` — JSON ``code`` != 200 (strict mode only).
* :class:`~netease_api.errors.NativeEncryptionUnavailable` — ``native``/``xeapi``
  mode requested; that envelope is not implemented.

Transport details
-----------------

The four supported modes and their payload formats are documented in
:mod:`netease_api.transport`. The default ``eapi`` mode POSTs AES-ECB encrypted
parameters to ``https://interface.music.163.com/eapi/<route>`` and injects
``os``, ``appver=9.6.30``, ``osver``, ``channel``, ``deviceId`` and
``requestId`` by default.
