"""Playlist detail, editing, subscription and discovery."""
from __future__ import annotations

from typing import Any, Iterable

from .base import ApiMixin

__all__ = ["PlaylistApi"]


class PlaylistApi(ApiMixin):
    """Playlist endpoints recovered from 9.6.30."""

    def playlist_detail(
        self,
        playlist_id: str | int,
        track_limit: int = 1000,
        offset: int = 0,
        **extra: Any,
    ) -> dict[str, Any]:
        """Playlist detail with tracks.  Route: ``v6/playlist/detail``.

        ``n`` is the track window size and ``s`` the track offset, matching the
        recovered parameter set (``id, v, c, trialMode, t, n, s``).
        """
        return self.call(
            "v6/playlist/detail",
            id=playlist_id,
            n=track_limit,
            s=offset,
            v=1,
            **extra,
        )

    def playlist_tracks(
        self, playlist_id: str | int, offset: int = 0, limit: int = 1000
    ) -> dict[str, Any]:
        """Track page of a playlist.  Same route as :meth:`playlist_detail`."""
        return self.playlist_detail(playlist_id, track_limit=limit, offset=offset)

    def playlist_detail_v4(
        self, playlist_id: str | int, **extra: Any
    ) -> dict[str, Any]:
        """Playlist detail (v4).  Route: ``playlist/v4/detail``."""
        return self.call("playlist/v4/detail", id=playlist_id, **extra)

    def playlist_dynamic(self, playlist_id: str | int) -> dict[str, Any]:
        """Playlist dynamic info.  Route: ``playlist/detail/dynamic``."""
        return self.call("playlist/detail/dynamic", id=playlist_id)

    def playlist_create(
        self,
        name: str,
        privacy: bool | int = False,
        type_: str = "NORMAL",
        track_ids: Iterable[str | int] | str | None = None,
    ) -> dict[str, Any]:
        """Create a playlist.  Route: ``playlist/create``.

        ``privacy`` is sent as an integer (``0`` public, ``10`` private).
        The service answers ``400 参数错误`` when it arrives as a JSON
        boolean, even though the recovered signature declares it as one, so
        booleans are normalised here.
        """
        if isinstance(privacy, bool):
            privacy_value = 10 if privacy else 0
        else:
            privacy_value = int(privacy)
        return self.call(
            "playlist/create",
            name=name,
            privacy=privacy_value,
            type=type_,
            trackIds=self._ids(track_ids) if track_ids is not None else None,
        )

    def playlist_delete(
        self, playlist_ids: Iterable[str | int] | str | int, self_owned: bool = True
    ) -> dict[str, Any]:
        """Delete playlists.  Route: ``playlist/remove``."""
        return self.call(
            "playlist/remove", ids=self._ids(playlist_ids), self=self._flag(self_owned)
        )

    def playlist_update_name(self, playlist_id: str | int, name: str) -> dict[str, Any]:
        """Rename.  Route: ``playlist/update/name``."""
        return self.call("playlist/update/name", id=playlist_id, name=name)

    def playlist_update_desc(self, playlist_id: str | int, desc: str) -> dict[str, Any]:
        """Change description.  Route: ``playlist/desc/update``."""
        return self.call("playlist/desc/update", id=playlist_id, desc=desc)

    def playlist_update_tags(
        self, playlist_id: str | int, tags: str | Iterable[str]
    ) -> dict[str, Any]:
        """Change tags.  Route: ``playlist/tags/update``."""
        value = tags if isinstance(tags, str) else ";".join(str(t) for t in tags)
        return self.call("playlist/tags/update", id=playlist_id, tags=value)

    def playlist_update_privacy(
        self, playlist_id: str | int, privacy: bool | int = True
    ) -> dict[str, Any]:
        """Change privacy.  Route: ``playlist/update/privacy``.

        The service uses ``10`` for a private playlist and ``0`` for a public
        one; booleans are mapped accordingly.
        """
        value = 10 if bool(privacy) else 0
        return self.call(
            "playlist/update/privacy", id=playlist_id, privacy=value
        )

    def playlist_subscribe(
        self, playlist_id: str | int, subscribe: bool = True
    ) -> dict[str, Any]:
        """Subscribe/unsubscribe.  Route: ``playlist/subscribe``.

        The classic protocol carries the direction in ``t`` (1 subscribe,
        0 unsubscribe); the recovered route only documents ``id`` and
        ``checkToken``.
        """
        return self.call(
            "playlist/subscribe", id=playlist_id, t=1 if subscribe else 0
        )

    def playlist_add_tracks(
        self,
        playlist_id: str | int,
        track_ids: Iterable[str | int] | str,
        op: str = "add",
    ) -> dict[str, Any]:
        """Add tracks.  Route: ``playlist/manipulate/tracks`` (``op='add'``)."""
        return self.call(
            "playlist/manipulate/tracks",
            pid=playlist_id,
            trackIds=self._json_ids(track_ids),
            op=op,
        )

    def playlist_del_tracks(
        self, playlist_id: str | int, track_ids: Iterable[str | int] | str
    ) -> dict[str, Any]:
        """Remove tracks.  Route: ``playlist/manipulate/tracks`` (``op='del'``)."""
        return self.playlist_add_tracks(playlist_id, track_ids, op="del")

    def playlist_reorder_tracks(
        self,
        playlist_id: str | int,
        track_ids: Iterable[str | int] | str,
        op: str = "update",
    ) -> dict[str, Any]:
        """Reorder tracks.  Route: ``playlist/manipulate/tracks``."""
        return self.playlist_add_tracks(playlist_id, track_ids, op=op)

    def playlist_subscribers(
        self, playlist_id: str | int, limit: int = 20, time: int = 0
    ) -> dict[str, Any]:
        """Subscribers.  Route: ``playlist/subscribers/bytime``."""
        return self.call(
            "playlist/subscribers/bytime", id=playlist_id, limit=limit, time=time
        )

    def playlist_category_list(
        self, cat: str = "全部", limit: int = 30
    ) -> dict[str, Any]:
        """Playlist categories.  Route: ``playlist/category/list``."""
        return self.call("playlist/category/list", cat=cat, limit=limit)

    def playlist_tags(self) -> dict[str, Any]:
        """Playlist tags.  Route: ``playlist/tags``."""
        return self.call("playlist/tags")

    def playlist_highquality_list(
        self, cat: str = "全部", lasttime: int = 0, limit: int = 30
    ) -> dict[str, Any]:
        """High-quality playlists.  Route: ``playlist/highquality/list``."""
        return self.call(
            "playlist/highquality/list", cat=cat, lasttime=lasttime, limit=limit
        )

    def playlist_highquality_tags(
        self, cat: str = "全部", lasttime: int = 0, limit: int = 30
    ) -> dict[str, Any]:
        """High-quality playlist tags.  Route: ``playlist/highquality/tags``."""
        return self.call(
            "playlist/highquality/tags", cat=cat, lasttime=lasttime, limit=limit
        )

    def playlist_list_get(
        self, playlist_ids: Iterable[str | int] | str
    ) -> dict[str, Any]:
        """Batch playlist summaries.  Route: ``playlist/list/get``."""
        return self.call("playlist/list/get", ids=self._ids(playlist_ids))

    def playlist_privilege(self, playlist_id: str | int) -> dict[str, Any]:
        """Playlist privilege.  Route: ``playlist/privilege``."""
        return self.call("playlist/privilege", id=playlist_id)

    def playlist_order_update(
        self, playlist_ids: Iterable[str | int] | str, self_owned: bool = True
    ) -> dict[str, Any]:
        """Reorder owned playlists.  Route: ``playlist/order/update``."""
        return self.call(
            "playlist/order/update",
            ids=self._ids(playlist_ids),
            self=self._flag(self_owned),
        )

    def playlist_import_from_local(
        self,
        song_ids: Iterable[str | int] | str,
        playlist_id: str | int,
        playlist_name: str,
        clean_before_import: bool = False,
    ) -> dict[str, Any]:
        """Import local songs.  Route: ``v1/playlist/importFromLocal``."""
        return self.call(
            "v1/playlist/importFromLocal",
            songIds=self._ids(song_ids),
            playlistId=playlist_id,
            playlistName=playlist_name,
            cleanBeforeImport=self._flag(clean_before_import),
        )

    def playlist_detail_rcmd(self, playlist_id: str | int) -> dict[str, Any]:
        """Recommended flag for a playlist.  Route: ``playlist/detail/rcmd/get``."""
        return self.call("playlist/detail/rcmd/get", id=playlist_id)

    def playlist_official_ids(self) -> dict[str, Any]:
        """Official playlist ids.  Route: ``playlist/official/ids/get``."""
        return self.call("playlist/official/ids/get")
