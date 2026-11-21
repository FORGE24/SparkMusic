Recovery notes
==============

This page summarizes how the catalog was recovered and what the Python client
does and does not reproduce. The full narrative, including the DEX analysis
method and encryption findings, is in the repository's ``API.md``; every route
is listed in :doc:`route_catalog` (and in ``ROUTES.md``).

Source APK
----------

* ``NeteaseCloudMusic_Music_official_9.6.30.261118204504_3264.apk``
* 211,786,350 bytes, 20 DEX files
* SHA-256 ``c9a8c1b30afb467426ceb88a985f9405eaa2f9d8a357bf76291c26d4c4cb40e1``

Method
------

1. Parse the DEX headers, map lists, class data and code items with a
   purpose-written pure-Python parser (``tools/dex_dump.py``), including
   instruction widths, payload pseudo-instructions and MUTF-8 strings.
2. Find calls to the generic request builders — ``y22/e.a`` … ``y22/e.g`` and
   the ``y32/a``, ``y32/b``, ``y32/c`` constructors — and scan backwards for
   the ``const-string`` that supplies the route.  In 9.6.30 those signatures
   are gone (R8 renames them per release), so this step falls back to
   scanning every method that contains route-shaped strings and the result
   is flagged as lower precision.
3. Recover parameter keys by tracking registers: ``const-string`` and
   ``move-object`` chains are followed, and the key register of each
   ``put``-like invocation is read (``35c``/``45cc``/``3rc`` formats,
   instance receiver at argument 0). Stale values expire after 80
   instructions.
4. Parse query-template routes so their placeholders contribute keys.
5. Add a second tier of routes inferred from route-shaped string constants in
   the string pool (marked ``inferred``).
6. Canonicalize away transport prefixes and query strings, then group by path
   root.

Result: 1,077 route-bearing records, 1,148 route strings, parameter lists for
286 records (514 unique keys), and a catalog of 1,293 canonical routes in 150
groups.

Recovered request architecture
------------------------------

.. code-block:: text

   NeteaseMusicApiImpl
           |
           v
   y22/e.a … y22/e.g(route, Map)
           |
           v
   y32/a, y32/b, y32/c (request objects)
           |
           v
   OkHttp interceptors
           |
           v
   native crypto: crypto.caesar.APICryptor,
                  crypto.caesarson.CaesarsonCryptor,
                  AegisNative, s32/c, s32/f

The app negotiates a per-session key via ``bsr/sk/get`` and marks encrypted
requests with ``x-encr-ssid``, ``x-encr-sskey``, ``X-Client-Enc-State``,
``x-aeapi`` and ``x-mg-zip``. The APK ships ``libcaesar.so``,
``libcaesarson.so``, ``libnesec.so``, ``libsec-lib.so``, ``libnetmobsec`` and
``libns.so``.

Encryption findings
-------------------

The classic ``weapi``/``eapi`` keys are absent from the 9.6.30 DEX files:

===============================  ===================================
Constant                         Occurrences in 20 DEX files
===============================  ===================================
``0CoJUm6Qyw8W8jud``             0
``e82ckenh8dichen8``             0
``md5forencrypt``                0
===============================  ===================================

Request encryption moved into the native session-key stack. The Python client
therefore does **not** reproduce the app's native envelope. Instead it
implements the four server-accepted transports used across NetEase clients:

================  ===============================================  ======================
Mode              URL                                              Body
================  ===============================================  ======================
``eapi``          ``https://interface.music.163.com/eapi/``        AES-ECB ``params``
``weapi``         ``https://music.163.com/weapi/``                 double AES-CBC + RSA
``api``           ``https://music.163.com/api/``                   plain form
``linuxapi``      ``https://music.163.com/api/linux/forward``      AES-ECB ``eparams``
================  ===============================================  ======================

The AES implementation is verified against the FIPS-197 vector and against
pycryptodome. ``native``/``xeapi`` mode raises
:class:`~netease_api.errors.NativeEncryptionUnavailable`.

Limitations
-----------

* Native session encryption and attestation are not reproduced; device-bound
  or risk-controlled endpoints may fail where the app succeeds.
* App-internal route groups (livestream, ad, icreator, sociallive, …) can be
  server-gated by account, region, plan or client version.
* Recovered parameters are key names, not value formats. Routes marked
  ``shared_params`` may list keys belonging to a sibling route.
* ``inferred`` routes are lower confidence and may contain ``%d``/``%s``
  placeholders that must be substituted.
* A few long-standing public routes used as compatibility fallbacks
  (``logout``, ``user/getfolloweds``, ``user/subcount``) are not in
  the 9.6.30 catalog; their docstrings say so.

Use only accounts and content you are authorized to access, and respect
NetEase's terms of service and applicable law.
