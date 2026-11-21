"""Encryption tests: known vectors, cross-checks and envelope shapes."""
from __future__ import annotations

import base64
import hashlib
import json
import unittest

from netease_api import crypto

try:  # optional oracle for decryption checks
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import unpad
except ImportError:  # pragma: no cover
    AES = None


def _unpad(data: bytes) -> bytes:
    return unpad(data, 16)


def _aes_ecb_decrypt(data: bytes, key: bytes) -> bytes:
    return _unpad(AES.new(key, AES.MODE_ECB).decrypt(data))


def _aes_cbc_decrypt(data: bytes, key: bytes, iv: bytes = crypto.WEAPI_IV) -> bytes:
    return _unpad(AES.new(key, AES.MODE_CBC, iv).decrypt(data))


class AesTests(unittest.TestCase):
    def test_fips197_vector(self) -> None:
        key = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
        plain = bytes.fromhex("00112233445566778899aabbccddeeff")
        expected = bytes.fromhex("69c4e0d86a7b0430d8cdb78070b4c55a")
        # aes_ecb_encrypt pads, so compare the first block and total length.
        out = crypto.aes_ecb_encrypt(plain, key)
        self.assertEqual(out[:16], expected)
        self.assertEqual(len(out), 32)

    def test_pkcs7_padding(self) -> None:
        for size in (0, 1, 15, 16, 17, 31, 32):
            data = b"x" * size
            padded = crypto.pkcs7_pad(data)
            self.assertEqual(len(padded) % 16, 0)
            self.assertGreater(len(padded), size)
            self.assertEqual(padded[-1], len(padded) - size)

    @unittest.skipIf(AES is None, "pycryptodome not installed")
    def test_ecb_matches_pycryptodome(self) -> None:
        key = b"e82ckenh8dichen8"
        for size in (1, 15, 16, 17, 100):
            data = (b"abc" * 100)[:size]
            ours = crypto.aes_ecb_encrypt(data, key)
            from Crypto.Util.Padding import pad

            theirs = AES.new(key, AES.MODE_ECB).encrypt(pad(data, 16))
            self.assertEqual(ours, theirs, f"size={size}")

    @unittest.skipIf(AES is None, "pycryptodome not installed")
    def test_cbc_matches_pycryptodome(self) -> None:
        key = b"0CoJUm6Qyw8W8jud"
        for size in (1, 16, 17, 100):
            data = (b"hello netease " * 20)[:size]
            ours = crypto.aes_cbc_encrypt(data, key)
            from Crypto.Util.Padding import pad

            theirs = AES.new(key, AES.MODE_CBC, crypto.WEAPI_IV).encrypt(pad(data, 16))
            self.assertEqual(ours, theirs, f"size={size}")


class WeapiTests(unittest.TestCase):
    def test_rsa_shape(self) -> None:
        secret = crypto.random_weapi_secret()
        self.assertEqual(len(secret), 16)
        enc = crypto.rsa_encrypt(secret)
        self.assertEqual(len(enc), 256)
        int(enc, 16)  # hex
        expected = pow(
            int.from_bytes(secret[::-1].encode("utf-8"), "big"),
            crypto.WEAPI_EXPONENT,
            crypto.WEAPI_MODULUS,
        )
        self.assertEqual(int(enc, 16), expected)

    @unittest.skipIf(AES is None, "pycryptodome not installed")
    def test_weapi_envelope_roundtrip(self) -> None:
        params = {"s": "海阔天空", "type": 1, "limit": 10}
        secret = "A" * 16
        out = crypto.weapi_encrypt(params, secret_key=secret)
        self.assertEqual(set(out), {"params", "encSecKey"})
        first = _aes_cbc_decrypt(base64.b64decode(out["params"]), secret.encode())
        inner_b64 = first  # outer decrypt yields base64 of inner ciphertext
        plain = _aes_cbc_decrypt(base64.b64decode(inner_b64), crypto.WEAPI_PRESET_KEY)
        self.assertEqual(json.loads(plain), params)


class EapiTests(unittest.TestCase):
    def test_digest(self) -> None:
        url = "/api/song/enhance/player/url/v1"
        text = '{"ids":"[1]"}'
        expected = hashlib.md5(
            f"nobody{url}use{text}md5forencrypt".encode()
        ).hexdigest()
        self.assertEqual(crypto.eapi_digest(url, text), expected)

    @unittest.skipIf(AES is None, "pycryptodome not installed")
    def test_eapi_envelope(self) -> None:
        params = {"ids": "[347230]", "level": "exhigh"}
        body = crypto.eapi_encrypt("/api/song/enhance/player/url/v1", params)
        self.assertEqual(body, body.upper())
        raw = _aes_ecb_decrypt(bytes.fromhex(body), crypto.EAPI_KEY)
        url, text, digest = raw.decode().split(crypto.EAPI_SEPARATOR)
        self.assertEqual(url, "/api/song/enhance/player/url/v1")
        self.assertEqual(json.loads(text), params)
        self.assertEqual(digest, crypto.eapi_digest(url, text))

    @unittest.skipIf(AES is None, "pycryptodome not installed")
    def test_linuxapi_envelope(self) -> None:
        params = {"ids": "[1]", "level": "standard"}
        body = crypto.linuxapi_encrypt("/api/song/enhance/player/url", params)
        raw = _aes_ecb_decrypt(bytes.fromhex(body), crypto.LINUXAPI_KEY)
        payload = json.loads(raw)
        self.assertEqual(payload["method"], "POST")
        self.assertEqual(payload["url"], "/api/song/enhance/player/url")
        self.assertEqual(payload["params"], params)


if __name__ == "__main__":
    unittest.main()
