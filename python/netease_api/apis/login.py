"""Login, captcha, QR, token and session endpoints."""
from __future__ import annotations

import hashlib
from typing import Any

from .base import ApiMixin

__all__ = ["LoginApi"]


class LoginApi(ApiMixin):
    """Authentication helpers.

    NetEase offers several generations of login endpoints.  This class uses
    the classic weapi/api forms (which the server still accepts and which work
    without the APK's native session handshake), while exposing the route names
    recovered from 9.6.30 where they overlap.
    """

    def login_cellphone(
        self,
        phone: str | int,
        password: str | None = None,
        captcha: str | None = None,
        country_code: str | int = "86",
        remember: bool = True,
        md5_password: bool = True,
        **extra: Any,
    ) -> dict[str, Any]:
        """Log in with phone + password or phone + SMS code.

        Route: ``login/cellphone`` (recovered).  Transport: weapi by default.
        On success the session cookies (``MUSIC_U``) are stored in the client.
        """
        params: dict[str, Any] = {
            "phone": str(phone),
            "countrycode": str(country_code).lstrip("+"),
            "rememberLogin": self._flag(remember),
        }
        if captcha is not None:
            params["captcha"] = str(captcha)
        elif password is not None:
            params["password"] = (
                hashlib.md5(password.encode("utf-8")).hexdigest()
                if md5_password
                else password
            )
        params.update(extra)
        return self.call("login/cellphone", _mode="weapi", **params)

    def login_email(
        self,
        email: str,
        password: str,
        remember: bool = True,
        md5_password: bool = True,
        **extra: Any,
    ) -> dict[str, Any]:
        """Log in with email + password (classic ``/weapi/login``)."""
        params = {
            "username": email,
            "password": (
                hashlib.md5(password.encode("utf-8")).hexdigest()
                if md5_password
                else password
            ),
            "rememberLogin": self._flag(remember),
        }
        params.update(extra)
        return self.call("login", _mode="weapi", **params)

    def login_qrcode_create(self, key: str | None = None) -> dict[str, Any]:
        """Create a QR login key (classic ``/weapi/login/qrcode/unikey``)."""
        params = self._clean(key=key, type=1)
        return self.call("login/qrcode/unikey", _mode="weapi", **params)

    def login_qrcode_check(self, key: str, type_: int = 1) -> dict[str, Any]:
        """Poll a QR login key (classic ``/weapi/login/qrcode/client/login``)."""
        return self.call("login/qrcode/client/login", _mode="weapi", key=key, type=type_)

    def login_qrcode_server(self, key: str, **params: Any) -> dict[str, Any]:
        """App QR server login (recovered ``login/qrcode/server/login``)."""
        return self.call("login/qrcode/server/login", key=key, **params)

    def login_sns(self, type_: str | int, token_json_str: str, **extra: Any) -> dict[str, Any]:
        """Third-party (SNS) login (recovered ``login/sns``)."""
        return self.call("login/sns", type=type_, tokenJsonStr=token_json_str, **extra)

    def login_refresh_token(self, **params: Any) -> dict[str, Any]:
        """Refresh a device token (recovered ``login/token/refresh``)."""
        return self.call("login/token/refresh", **params)

    def login_find_last_token(self, **params: Any) -> dict[str, Any]:
        """Recover the last used token (recovered ``login/token/findlasttoken``)."""
        return self.call("login/token/findlasttoken", **params)

    def captcha_send(
        self, phone: str | int, country_code: str | int = "86"
    ) -> dict[str, Any]:
        """Send an SMS code (``sms/captcha/sent``)."""
        return self.call(
            "sms/captcha/sent",
            _mode="weapi",
            cellphone=str(phone),
            ctcode=str(country_code).lstrip("+"),
        )

    def captcha_verify(
        self, phone: str | int, captcha: str, country_code: str | int = "86"
    ) -> dict[str, Any]:
        """Verify an SMS code (``sms/captcha/verify``)."""
        return self.call(
            "sms/captcha/verify",
            _mode="weapi",
            cellphone=str(phone),
            captcha=captcha,
            ctcode=str(country_code).lstrip("+"),
        )

    def register_cellphone(
        self,
        phone: str | int,
        password: str,
        captcha: str,
        nickname: str,
        country_code: str | int = "86",
        **extra: Any,
    ) -> dict[str, Any]:
        """Register by phone (classic ``/weapi/register/cellphone``)."""
        return self.call(
            "register/cellphone",
            _mode="weapi",
            phone=str(phone),
            password=hashlib.md5(password.encode("utf-8")).hexdigest(),
            captcha=captcha,
            nickname=nickname,
            countrycode=str(country_code).lstrip("+"),
            **extra,
        )

    def account(self) -> dict[str, Any]:
        """Current account/profile (classic ``/api/nuser/account/get``)."""
        return self.call("nuser/account/get", _mode="api")

    def logout(self) -> dict[str, Any]:
        """Log out (classic ``/api/logout``)."""
        return self.call("logout", _mode="api")
