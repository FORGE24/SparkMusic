Authentication and quality
==========================

Most write endpoints and personalized reads need a logged-in session cookie
(``MUSIC_U``). Lossless and Hi-Res URLs additionally require the account to be
entitled to them; the client reproduces the request but does not grant
entitlements.

Cookie login (recommended)
--------------------------

Reuse a session from a logged-in client:

1. Open ``https://music.163.com`` and log in.
2. Open DevTools → Application → Storage → Cookies → ``https://music.163.com``.
3. Copy ``MUSIC_U`` (and ``__csrf`` when present).

.. code-block:: python

   from netease_api import NeteaseClient

   client = NeteaseClient(cookies="MUSIC_U=...; __csrf=...")

Or via the environment:

.. code-block:: console

   $ set NETEASE_COOKIE=MUSIC_U=...; __csrf=...

.. code-block:: python

   client = NeteaseClient.from_env()

.. note::

   ``MUSIC_U`` is HttpOnly, so ``document.cookie`` in the browser console will
   not show it. Use the Application tab or copy the ``Cookie`` header from a
   Network request.

Phone and email login
---------------------

.. code-block:: python

   client = NeteaseClient()
   client.login_cellphone("13800000000", "password")
   client.save_cookies("cookies.json")

The route is ``login/cellphone`` over weapi. The password is MD5-hashed for
you; pass ``md5_password=False`` to send it unchanged. New devices can trigger
SMS verification or risk control (for example code ``8821``); request a code
and log in with it instead:

.. code-block:: python

   client.captcha_send("13800000000")
   client.login_cellphone("13800000000", captcha="123456")

Email login uses the long-standing public ``login`` route:

.. code-block:: python

   client.login_email("you@example.com", "password")

QR login
--------

.. code-block:: python

   data = client.login_qrcode_create()   # contains unikey
   client.login_qrcode_check(key)        # poll until code == 803

The classic QR helpers are compatibility fallbacks. The 9.6.30 app uses
``login/qrcode/server/login``, which expects app-side tokens; browser-cookie
login is usually simpler.

After any login
---------------

.. code-block:: python

   print(client.whoami())        # profile and account; sets client.user_id
   client.save_cookies("cookies.json")
   client = NeteaseClient.from_cookie_file("cookies.json")

Quality levels and FLAC
-----------------------

Request a playback URL with a quality level:

.. code-block:: python

   # standard | higher | exhigh | lossless | hires | jyeffect | sky | jymaster
   resp = client.song_url(347230, level="lossless", encode_type="flac")
   item = resp["data"][0]
   print(item["url"], item["type"], item["level"], item["size"], item["code"])

``lossless`` requests CD-quality FLAC; ``hires`` and ``jymaster`` require
higher plans. The download route is also available:

.. code-block:: python

   client.song_download_url(347230, level="lossless")

Downloading the returned URL (it expires, typically within about 20 minutes):

.. code-block:: python

   import requests

   url = item["url"]
   response = requests.get(
       url,
       headers={
           "User-Agent": "Mozilla/5.0",
           "Referer": "https://music.163.com/",
       },
   )
   response.raise_for_status()
   extension = "flac" if response.content[:4] == b"fLaC" else item.get("type", "bin")
   with open(f"347230.{extension}", "wb") as handle:
       handle.write(response.content)

Check the account's entitlement with ``client.vip_info()`` or
``client.vip_auth_soundquality()``.

Troubleshooting
---------------

.. list-table::
   :header-rows: 1
   :widths: 30 55

   * - Symptom
     - Cause
   * - ``url`` is ``null`` with ``code`` 200
     - Account lacks the requested tier, the track is region-locked, or no
       lossless master exists
   * - ``code`` 301/403
     - Not logged in, expired cookie, or a cookie from the wrong domain
   * - Download returns 403
     - Expired URL, or missing ``Referer``/user agent
   * - Login returns 8821/503
     - Risk control; use a browser cookie instead of password login
   * - Requested level is silently downgraded
     - The server applied the account's entitlement; inspect the returned
       ``level`` and ``type``

.. warning::

   Use only accounts and content you are authorized to access. The client calls
   the same endpoints as the app and does not bypass payment, DRM or regional
   restrictions. Respect NetEase's terms of service and applicable law.
