"""Encryption primitives used by the NetEase Cloud Music web/eapi transports.

Nothing here is copied from the APK: the 9.6.30 client no longer contains the
classic weapi/eapi keys (see API.md).  These are the well-known, publicly
documented schemes the server still accepts, re-implemented so the recovered
route catalog can be exercised from Python.

The package has no third-party crypto dependency.  AES-128 is implemented
below (encryption only), RSA is a modular exponentiation with the public
NetEase key, and hashing uses :mod:`hashlib`.
"""
from __future__ import annotations

import base64
import hashlib
import json
import secrets
import string
from typing import Any, Mapping

__all__ = [
    "EAPI_KEY",
    "LINUXAPI_KEY",
    "WEAPI_PRESET_KEY",
    "WEAPI_IV",
    "WEAPI_PUBKEY",
    "aes_cbc_encrypt",
    "aes_ecb_encrypt",
    "eapi_digest",
    "eapi_encrypt",
    "linuxapi_encrypt",
    "rsa_encrypt",
    "weapi_encrypt",
    "random_weapi_secret",
    "pkcs7_pad",
]

WEAPI_PRESET_KEY = b"0CoJUm6Qyw8W8jud"
WEAPI_IV = b"0102030405060708"
EAPI_KEY = b"e82ckenh8dichen8"
LINUXAPI_KEY = b"rFgB&h#%2?^eDg:Q"
WEAPI_PUBKEY = (
    "00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725"
    "152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ec"
    "bda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813"
    "cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7"
)
WEAPI_EXPONENT = 0x10001
WEAPI_MODULUS = int(WEAPI_PUBKEY, 16)
EAPI_SEPARATOR = "-36cd479b6b5-"

_SBOX_HEX = (
    "637c777bf26b6fc53001672bfed7ab76"
    "ca82c97dfa5947f0add4a2af9ca472c0"
    "b7fd9326363ff7cc34a5e5f171d83115"
    "04c723c31896059a071280e2eb27b275"
    "09832c1a1b6e5aa0523bd6b329e32f84"
    "53d100ed20fcb15b6acbbe394a4c58cf"
    "d0efaafb434d338545f9027f503c9fa8"
    "51a3408f929d38f5bcb6da2110fff3d2"
    "cd0c13ec5f974417c4a77e3d645d1973"
    "60814fdc222a908846eeb814de5e0bdb"
    "e0323a0a4906245cc2d3ac629195e479"
    "e7c8376d8dd54ea96c56f4ea657aae08"
    "ba78252e1ca6b4c6e8dd741f4bbd8b8a"
    "703eb5664803f60e613557b986c11d9e"
    "e1f8981169d98e949b1e87e9ce5528df"
    "8ca1890dbfe6426841992d0fb054bb16"
)
SBOX = bytes.fromhex(_SBOX_HEX)


def _xtime(value: int) -> int:
    value <<= 1
    if value & 0x100:
        value ^= 0x11B
    return value & 0xFF


def _expand_key(key: bytes) -> list[list[int]]:
    if len(key) != 16:
        raise ValueError("AES-128 key must be exactly 16 bytes")
    words = [list(key[i:i + 4]) for i in range(0, 16, 4)]
    rcon = 1
    for i in range(4, 44):
        temp = list(words[i - 1])
        if i % 4 == 0:
            temp = temp[1:] + temp[:1]
            temp = [SBOX[b] for b in temp]
            temp[0] ^= rcon
            rcon = _xtime(rcon)
        words.append([words[i - 4][j] ^ temp[j] for j in range(4)])
    return words


def _add_round_key(state: list[int], words: list[list[int]]) -> None:
    for c, word in enumerate(words):
        base = 4 * c
        for r in range(4):
            state[base + r] ^= word[r]


def _shift_rows(state: list[int]) -> list[int]:
    s = state
    return [
        s[0], s[5], s[10], s[15],
        s[4], s[9], s[14], s[3],
        s[8], s[13], s[2], s[7],
        s[12], s[1], s[6], s[11],
    ]


def _mix_columns(state: list[int]) -> list[int]:
    out = [0] * 16
    for c in range(4):
        i = 4 * c
        a0, a1, a2, a3 = state[i:i + 4]
        out[i] = _xtime(a0) ^ (_xtime(a1) ^ a1) ^ a2 ^ a3
        out[i + 1] = a0 ^ _xtime(a1) ^ (_xtime(a2) ^ a2) ^ a3
        out[i + 2] = a0 ^ a1 ^ _xtime(a2) ^ (_xtime(a3) ^ a3)
        out[i + 3] = (_xtime(a0) ^ a0) ^ a1 ^ a2 ^ _xtime(a3)
    return out


def _encrypt_block(block: bytes, key: bytes) -> bytes:
    if len(block) != 16:
        raise ValueError("AES block must be exactly 16 bytes")
    words = _expand_key(key)
    state = list(block)
    _add_round_key(state, words[0:4])
    for round_no in range(1, 10):
        state = [SBOX[b] for b in state]
        state = _shift_rows(state)
        state = _mix_columns(state)
        _add_round_key(state, words[4 * round_no:4 * round_no + 4])
    state = [SBOX[b] for b in state]
    state = _shift_rows(state)
    _add_round_key(state, words[40:44])
    return bytes(state)


def pkcs7_pad(data: bytes, block_size: int = 16) -> bytes:
    pad = block_size - (len(data) % block_size)
    return data + bytes([pad]) * pad


def aes_ecb_encrypt(data: bytes, key: bytes) -> bytes:
    data = pkcs7_pad(data)
    return b"".join(_encrypt_block(data[i:i + 16], key) for i in range(0, len(data), 16))


def aes_cbc_encrypt(data: bytes, key: bytes, iv: bytes = WEAPI_IV) -> bytes:
    if len(iv) != 16:
        raise ValueError("AES IV must be exactly 16 bytes")
    data = pkcs7_pad(data)
    out = bytearray()
    previous = iv
    for i in range(0, len(data), 16):
        block = bytes(a ^ b for a, b in zip(data[i:i + 16], previous))
        previous = _encrypt_block(block, key)
        out += previous
    return bytes(out)


def random_weapi_secret() -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(16))


def rsa_encrypt(text: str) -> str:
    """NetEase weapi RSA: reversed secret key, textbook RSA, 256 hex chars."""
    reversed_bytes = text[::-1].encode("utf-8")
    message = int.from_bytes(reversed_bytes, "big")
    encrypted = pow(message, WEAPI_EXPONENT, WEAPI_MODULUS)
    return format(encrypted, "x").zfill(256)


def weapi_encrypt(params: Mapping[str, Any], secret_key: str | None = None) -> dict[str, str]:
    text = json.dumps(dict(params), ensure_ascii=False, separators=(",", ":"))
    secret_key = secret_key or random_weapi_secret()
    first = base64.b64encode(aes_cbc_encrypt(text.encode("utf-8"), WEAPI_PRESET_KEY, WEAPI_IV))
    second = base64.b64encode(aes_cbc_encrypt(first, secret_key.encode("utf-8"), WEAPI_IV))
    return {"params": second.decode("ascii"), "encSecKey": rsa_encrypt(secret_key)}


def eapi_digest(url: str, text: str) -> str:
    return hashlib.md5(f"nobody{url}use{text}md5forencrypt".encode("utf-8")).hexdigest()


def eapi_encrypt(url: str, params: Mapping[str, Any]) -> str:
    """Return the uppercase hex body used by /eapi/ endpoints.

    ``url`` must be the API path the payload is signed for, e.g.
    ``/api/song/enhance/player/url/v1``.
    """
    text = json.dumps(dict(params), ensure_ascii=False, separators=(",", ":"))
    message = f"{url}{EAPI_SEPARATOR}{text}{EAPI_SEPARATOR}{eapi_digest(url, text)}"
    return aes_ecb_encrypt(message.encode("utf-8"), EAPI_KEY).hex().upper()


def linuxapi_encrypt(url: str, params: Mapping[str, Any]) -> str:
    payload = {"method": "POST", "url": url, "params": dict(params)}
    text = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    return aes_ecb_encrypt(text.encode("utf-8"), LINUXAPI_KEY).hex().upper()
