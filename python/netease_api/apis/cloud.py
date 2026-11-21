"""Cloud disk (music cloud) and VIP endpoints."""
from __future__ import annotations

from typing import Any, Iterable

from .base import ApiMixin

__all__ = ["CloudApi", "VipApi"]


class CloudApi(ApiMixin):
    """Music cloud disk endpoints recovered from 9.6.30."""

    def cloud_songs(self, limit: int = 20, offset: int = 0, **extra: Any) -> dict[str, Any]:
        """Cloud songs.  Route: ``v3/cloud/get``."""
        return self.call("v3/cloud/get", limit=limit, offset=offset, **extra)

    def cloud_song_status(self, **extra: Any) -> dict[str, Any]:
        """Cloud song processing status.  Route: ``v1/cloud/music/status``."""
        return self.call("v1/cloud/music/status", **extra)

    def cloud_upload_check(
        self,
        file_name: str,
        file_size: int,
        file_md5: str,
        files: Iterable[dict[str, Any]] | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Check whether a file can be uploaded.  Route: ``cloud/file/upload/check``."""
        return self.call(
            "cloud/file/upload/check",
            fileName=file_name,
            fileSize=file_size,
            fileMd5=file_md5,
            files=self._json(files) if files is not None else None,
            **extra,
        )

    def cloud_upload_create(
        self,
        file_name: str,
        file_size: int,
        file_md5: str,
        nos_key: str = "",
        **extra: Any,
    ) -> dict[str, Any]:
        """Create an upload task.  Route: ``cloud/file/upload/create``."""
        return self.call(
            "cloud/file/upload/create",
            fileName=file_name,
            fileSize=file_size,
            fileMd5=file_md5,
            fileNosKey=nos_key,
            **extra,
        )

    def cloud_upload_status(self, **extra: Any) -> dict[str, Any]:
        """Upload task status.  Route: ``cloud/file/upload/status``."""
        return self.call("cloud/file/upload/status", **extra)

    def cloud_upload_cancel(self, **extra: Any) -> dict[str, Any]:
        """Cancel an upload.  Route: ``cloud/file/upload/cancel``."""
        return self.call("cloud/file/upload/cancel", **extra)

    def cloud_upload_check_v2(self, **extra: Any) -> dict[str, Any]:
        """Upload check (v2).  Route: ``cloud/upload/check/v2``."""
        return self.call("cloud/upload/check/v2", **extra)

    def cloud_pub(self, **params: Any) -> dict[str, Any]:
        """Publish a cloud song.  Route: ``cloud/pub/v2``.

        The recovered method sends a large metadata set (``song``, ``artist``,
        ``album``, ``bitrate``, ``songId``...); pass it through.
        """
        return self.call("cloud/pub/v2", **params)

    def cloud_import(
        self,
        song_id: str | int,
        bitrate: int = 320000,
        song: str = "",
        artist: str = "",
        album: str = "",
        file_name: str = "",
        **extra: Any,
    ) -> dict[str, Any]:
        """Match an uploaded file to a library song.  Route: ``cloud/user/song/import``."""
        return self.call(
            "cloud/user/song/import",
            songId=song_id,
            bitrate=bitrate,
            song=song,
            artist=artist,
            album=album,
            fileName=file_name,
            **extra,
        )

    def cloud_delete(self, song_ids: Iterable[str | int] | str) -> dict[str, Any]:
        """Delete cloud songs.  Route: ``cloud/del``."""
        return self.call("cloud/del", songIds=self._ids(song_ids))

    def cloud_lyric(
        self,
        song_id: str | int,
        user_id: str | int | None = None,
        kv: int = 0,
        lv: int = 0,
        **extra: Any,
    ) -> dict[str, Any]:
        """Cloud lyric.  Route: ``cloud/lyric/get``."""
        return self.call(
            "cloud/lyric/get",
            songId=song_id,
            userId=user_id,
            kv=kv,
            lv=lv,
            **extra,
        )

    def cloud_records(
        self, record_ids: Iterable[str | int] | str = "", **extra: Any
    ) -> dict[str, Any]:
        """Cloud import records.  Route: ``cloud/record/get``."""
        return self.call("cloud/record/get", recordIds=self._ids(record_ids), **extra)

    def cloud_sort_update(self, **extra: Any) -> dict[str, Any]:
        """Reorder cloud songs.  Route: ``v1/cloud/sort/update``."""
        return self.call("v1/cloud/sort/update", **extra)

    def cloud_user_config(self) -> dict[str, Any]:
        """Cloud user configuration.  Route: ``cloud/file/user/config/get``."""
        return self.call("cloud/file/user/config/get")

    def cloud_user_menu(self) -> dict[str, Any]:
        """Cloud user menu.  Route: ``cloud/user/menu/get``."""
        return self.call("cloud/user/menu/get")

    def cloud_guide(self) -> dict[str, Any]:
        """Cloud upload guide.  Route: ``cloud/guide/get``."""
        return self.call("cloud/guide/get")

    def cloud_upload_settings(self, **extra: Any) -> dict[str, Any]:
        """Upload settings.  Route: ``cloud/user/settings/upload/set``."""
        return self.call("cloud/user/settings/upload/set", **extra)


class VipApi(ApiMixin):
    """VIP membership and cashier endpoints."""

    def vip_info(self, **extra: Any) -> dict[str, Any]:
        """VIP membership info.  Route: ``music-vip-membership/client/vip/info``."""
        return self.call("music-vip-membership/client/vip/info", **extra)

    def vip_config_url(self, **extra: Any) -> dict[str, Any]:
        """VIP config URL.  Route: ``vip/config/url``."""
        return self.call("vip/config/url", **extra)

    def vip_cashier_nonts(self, **extra: Any) -> dict[str, Any]:
        """Cashier (non-TS).  Route: ``vip/cashier/nonts/get``."""
        return self.call("vip/cashier/nonts/get", **extra)

    def vip_cashier_popup(self, **extra: Any) -> dict[str, Any]:
        """Cashier popup.  Route: ``vip/cashier/tspopup/get``."""
        return self.call("vip/cashier/tspopup/get", **extra)

    def vip_newuser_give_submit(self, **extra: Any) -> dict[str, Any]:
        """New-user VIP gift.  Route: ``vip/newuser/give/submit``."""
        return self.call("vip/newuser/give/submit", **extra)

    def vip_push_info(self, **extra: Any) -> dict[str, Any]:
        """VIP push info.  Route: ``vip/yi/dong/push/info/get``."""
        return self.call("vip/yi/dong/push/info/get", **extra)

    def vip_auth_query(self) -> dict[str, Any]:
        """VIP auth state.  Route: ``vipauth/app/auth/query``."""
        return self.call("vipauth/app/auth/query")

    def vip_auth_soundquality(self) -> dict[str, Any]:
        """VIP sound-quality auth.  Route: ``vipauth/app/auth/soundquality/andriod/query``."""
        return self.call("vipauth/app/auth/soundquality/andriod/query")

    def vip_auth_memberlogo(self) -> dict[str, Any]:
        """Member logo identity.  Route: ``vipauth/memberlogo/identity``."""
        return self.call("vipauth/memberlogo/identity")
