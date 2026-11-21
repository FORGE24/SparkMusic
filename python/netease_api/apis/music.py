"""Song, album, artist and MV endpoints."""
from __future__ import annotations

from typing import Any, Iterable

from .base import ApiMixin

__all__ = ["SongApi", "AlbumApi", "ArtistApi", "MvApi"]


def _id_objects(ids: Iterable[str | int] | str | int) -> list[dict[str, Any]]:
    if isinstance(ids, (str, int)):
        values: list[str | int] = [ids]
    else:
        values = list(ids)
    result = []
    for value in values:
        try:
            result.append({"id": int(value)})
        except (TypeError, ValueError):
            result.append({"id": value})
    return result


class SongApi(ApiMixin):
    """Song detail, playback URLs, lyrics and song-level actions."""

    def song_detail(
        self,
        ids: Iterable[str | int] | str | int,
        level: str = "standard",
        **extra: Any,
    ) -> dict[str, Any]:
        """Batch song detail.  Route: ``v3/song/detail``.

        The app sends ``id`` (comma list) and ``c`` (JSON ``[{"id": ...}]``);
        ``v``/``rv`` are protocol version fields.  ``level`` is accepted for
        symmetry with other clients and forwarded as ``level``.
        """
        id_list = self._ids(ids)
        return self.call(
            "v3/song/detail",
            id=id_list,
            c=self._json(_id_objects(ids)),
            v=1,
            rv=1,
            level=level,
            **extra,
        )

    def song_url(
        self,
        ids: Iterable[str | int] | str | int,
        level: str = "standard",
        encode_type: str = "flac",
        **extra: Any,
    ) -> dict[str, Any]:
        """Playback URLs.  Route: ``song/enhance/player/url/v1``.

        ``ids`` is sent as a JSON array string, matching the recovered query
        template ``ids=%s&level=%s&encodeType=%s...``.
        """
        return self.call(
            "song/enhance/player/url/v1",
            ids=self._json_ids(ids),
            level=level,
            encodeType=encode_type,
            **extra,
        )

    def song_download_url(
        self, song_id: str | int, level: str = "standard", **extra: Any
    ) -> dict[str, Any]:
        """Download URL.  Route: ``song/enhance/download/url/v1``."""
        return self.call(
            "song/enhance/download/url/v1", id=song_id, level=level, **extra
        )

    def song_download_mv_url(
        self, mv_id: str | int, resolution: int = 1080, **extra: Any
    ) -> dict[str, Any]:
        """MV file URL.  Route: ``song/enhance/download/mv/url``."""
        return self.call(
            "song/enhance/download/mv/url", id=mv_id, r=resolution, **extra
        )

    def song_lyric(
        self, song_id: str | int, cp: bool = False, **extra: Any
    ) -> dict[str, Any]:
        """Lyrics.  Route: ``song/lyric/v1`` (query template recovered)."""
        return self.call(
            "song/lyric/v1",
            id=song_id,
            cp=self._flag(cp),
            lv=-1,
            kv=-1,
            tv=-1,
            **extra,
        )

    def song_lyric_classic(self, song_id: str | int, **extra: Any) -> dict[str, Any]:
        """Classic lyric route ``song/lyric`` (inferred from the string pool)."""
        return self.call("song/lyric", id=song_id, lv=-1, kv=-1, tv=-1, **extra)

    def song_like(
        self,
        song_id: str | int,
        like: bool = True,
        user_id: str | int | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Like/unlike a song.  Route: ``song/like``.

        NetEase also expects the account id in ``userid``; the client fills it
        from the last login response when available.
        """
        uid = user_id or getattr(self, "user_id", None)
        return self.call(
            "song/like",
            trackId=song_id,
            like=self._flag(like),
            userid=uid,
            **extra,
        )

    def song_like_get(self) -> dict[str, Any]:
        """Liked-song metadata.  Route: ``song/like/get``."""
        return self.call("song/like/get")

    def song_privilege(
        self, ids: Iterable[str | int] | str | int, **extra: Any
    ) -> dict[str, Any]:
        """Playback privileges.  Route: ``song/enhance/privilege``."""
        return self.call("song/enhance/privilege", ids=self._json_ids(ids), **extra)

    def song_enhance_info(
        self, ids: Iterable[str | int] | str | int, **extra: Any
    ) -> dict[str, Any]:
        """Enhanced song metadata.  Route: ``song/enhance/info/get``."""
        return self.call("song/enhance/info/get", ids=self._ids(ids), **extra)

    def song_chorus(self, song_id: str | int, **extra: Any) -> dict[str, Any]:
        """Chorus segment.  Route: ``song/chorus``."""
        return self.call("song/chorus", id=song_id, **extra)

    def song_beat_detail(self, song_id: str | int, **extra: Any) -> dict[str, Any]:
        """Beat/rhythm analysis.  Route: ``song/beat/detail``."""
        return self.call("song/beat/detail", id=song_id, **extra)

    def song_copyright_rcmd(self, song_id: str | int) -> dict[str, Any]:
        """Copyright recommendation.  Route: ``song/copyright/rcmd``."""
        return self.call("song/copyright/rcmd", songid=song_id)

    def song_grey_rcmd(self, song_id: str | int) -> dict[str, Any]:
        """Unavailable-song recommendation.  Route: ``song/grey/rcmd``."""
        return self.call("song/grey/rcmd", songid=song_id)

    def song_toast(
        self, song_id: str | int, ext_play: bool = False
    ) -> dict[str, Any]:
        """Playback toast/notice.  Route: ``song/toast``."""
        return self.call("song/toast", id=song_id, extPlay=self._flag(ext_play))

    def song_red_count(self) -> dict[str, Any]:
        """Red-heart count.  Route: ``song/red/count``."""
        return self.call("song/red/count")

    def song_play_more_list(
        self, song_id: str | int, **extra: Any
    ) -> dict[str, Any]:
        """'Play more' panel.  Route: ``song/play/more/list/v2``."""
        return self.call("song/play/more/list/v2", songId=song_id, **extra)

    def song_music_detail(self, song_id: str | int, **extra: Any) -> dict[str, Any]:
        """Song detail (new module).  Route: ``song/music/detail/get``."""
        return self.call("song/music/detail/get", songId=song_id, **extra)

    def song_type_detail(self, song_id: str | int, **extra: Any) -> dict[str, Any]:
        """Song type detail.  Route: ``song/type/detail/get``."""
        return self.call("song/type/detail/get", songId=song_id, **extra)


class AlbumApi(ApiMixin):
    """Album detail, subscription and new-album discovery."""

    def album_detail(self, album_id: str | int) -> dict[str, Any]:
        """Album detail.  Route: ``album/{id}``.

        The APK's ``album/v3/detail`` route also expects an encrypted
        ``cache_key`` computed from ``e_r`` and the album id; without it the
        service answers ``400 参数错误``.  The classic album route returns the
        same payload (album metadata plus its songs) and needs only the id.
        """
        return self.call(f"album/{album_id}")

    def album_dynamic(self, album_id: str | int) -> dict[str, Any]:
        """Dynamic album info.  Route: ``album/detail/dynamic``."""
        return self.call("album/detail/dynamic", id=album_id)

    def album_new(
        self, area: str = "ALL", limit: int = 30, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """New albums.  Route: ``album/new`` (classic parameters)."""
        return self.call(
            "album/new", area=area, limit=limit, offset=offset, total=True, **extra
        )

    def album_subscribe(self, album_id: str | int, subscribe: bool = True) -> dict[str, Any]:
        """Subscribe/unsubscribe.  Routes: ``album/sub`` / ``album/unsub``."""
        return self.call(
            "album/sub" if subscribe else "album/unsub", id=album_id
        )

    def album_sublist(self) -> dict[str, Any]:
        """Subscribed albums.  Route: ``album/sublist``."""
        return self.call("album/sublist")

    def album_privilege(self, album_id: str | int) -> dict[str, Any]:
        """Album privilege.  Route: ``album/privilege``."""
        return self.call("album/privilege", id=album_id)

    def album_play(self, album_id: str | int) -> dict[str, Any]:
        """Play an album.  Route: ``album/play``."""
        return self.call("album/play", id=album_id)


class ArtistApi(ApiMixin):
    """Artist profile, songs, albums and subscription."""

    def artist_detail(self, artist_id: str | int) -> dict[str, Any]:
        """Artist detail.  Route: ``artist/detail/dynamic/v2``."""
        return self.call("artist/detail/dynamic/v2", artistId=artist_id)

    def artist_detail_dynamic(self, user_id: str | int) -> dict[str, Any]:
        """Artist dynamic detail by user id.  Route: ``artist/detail/dynamic``."""
        return self.call("artist/detail/dynamic", userId=user_id)

    def artist_songs(
        self,
        artist_id: str | int,
        limit: int = 50,
        offset: int = 0,
        order: str = "hot",
        work_type: int = 1,
        private_cloud: bool = False,
        **extra: Any,
    ) -> dict[str, Any]:
        """Artist songs.  Route: ``v2/artist/songs`` (query template recovered)."""
        return self.call(
            "v2/artist/songs",
            id=artist_id,
            limit=limit,
            offset=offset,
            order=order,
            work_type=work_type,
            private_cloud=self._flag(private_cloud),
            **extra,
        )

    def artist_albums(
        self, artist_id: str | int, limit: int = 30, offset: int = 0
    ) -> dict[str, Any]:
        """Artist albums.  Route: ``artist/albums/{id}``."""
        return self.call(f"artist/albums/{artist_id}", limit=limit, offset=offset)

    def artist_albums_bytype(
        self,
        artist_id: str | int,
        limit: int = 30,
        index: int = 0,
        sort: int = 0,
    ) -> dict[str, Any]:
        """Artist albums grouped by type.  Route: ``artist/albums/bytype``."""
        return self.call(
            "artist/albums/bytype", artist_id=artist_id, limit=limit, index=index, sort=sort
        )

    def artist_top_songs(self, artist_id: str | int, **extra: Any) -> dict[str, Any]:
        """Top songs.  Route: ``v1/artist/top/song``."""
        return self.call("v1/artist/top/song", id=artist_id, **extra)

    def artist_subscribe(self, artist_id: str | int) -> dict[str, Any]:
        """Subscribe.  Route: ``v1/artist/sub``."""
        return self.call("v1/artist/sub", artistId=artist_id)

    def artist_unsubscribe(self, artist_id: str | int) -> dict[str, Any]:
        """Unsubscribe.  Route: ``artist/unsub``."""
        return self.call("artist/unsub", artistId=artist_id)

    def artist_subscribe_batch(
        self, artist_ids: Iterable[str | int] | str
    ) -> dict[str, Any]:
        """Batch subscribe.  Route: ``artist/sub/batch``."""
        return self.call("artist/sub/batch", artistIds=self._ids(artist_ids))

    def artist_follow_count(self, user_id: str | int) -> dict[str, Any]:
        """Follower count.  Route: ``artist/follow/count/get``."""
        return self.call("artist/follow/count/get", userId=user_id)

    def artist_video(
        self, artist_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Artist videos.  Route: ``artist/video``."""
        return self.call("artist/video", id=artist_id, limit=limit, offset=offset, **extra)

    def artist_all(
        self,
        offset: int = 0,
        limit: int = 30,
        initial: str = "",
        category_code: str | int = "",
    ) -> dict[str, Any]:
        """Artist index.  Route: ``artist/all``."""
        return self.call(
            "artist/all", offset=offset, limit=limit, initial=initial, categoryCode=category_code
        )

    def artist_hot(
        self, offset: int = 0, limit: int = 30, initial: str = ""
    ) -> dict[str, Any]:
        """Hot artists.  Route: ``artist/hot``."""
        return self.call("artist/hot", offset=offset, limit=limit, initial=initial)

    def artist_song_count(self, artist_id: str | int) -> dict[str, Any]:
        """Song counts.  Route: ``artist/song/count``."""
        return self.call("artist/song/count", artistId=artist_id)

    def artist_similar(self, artist_id: str | int, limit: int = 20) -> dict[str, Any]:
        """Similar artists.  Route: ``v1/similar/artist/get``."""
        return self.call("v1/similar/artist/get", artistId=artist_id, limit=limit)


class MvApi(ApiMixin):
    """MV detail, playback and listings."""

    def mv_detail(self, mv_id: str | int) -> dict[str, Any]:
        """MV detail.  Route: ``v1/mv/detail``."""
        return self.call("v1/mv/detail", id=mv_id)

    def mv_url(self, mv_id: str | int, resolution: int = 1080) -> dict[str, Any]:
        """MV playback URL.  Route: ``song/enhance/download/mv/url``."""
        return self.call("song/enhance/download/mv/url", id=mv_id, r=resolution)

    def mv_all(
        self, limit: int = 30, offset: int = 0, tags: str = ""
    ) -> dict[str, Any]:
        """All MVs.  Route: ``mv/all``."""
        return self.call("mv/all", limit=limit, offset=offset, tags=tags)

    def mv_tags(self, limit: int = 30, offset: int = 0, tags: str = "") -> dict[str, Any]:
        """MV tags.  Route: ``mv/tags``."""
        return self.call("mv/tags", limit=limit, offset=offset, tags=tags)

    def mv_exclusive_rcmd(self, limit: int = 30) -> dict[str, Any]:
        """Exclusive MV recommendations.  Route: ``mv/exclusive/rcmd``."""
        return self.call("mv/exclusive/rcmd", limit=limit)

    def mv_first_allarea(self, limit: int = 10) -> dict[str, Any]:
        """First/all-area MVs.  Route: ``mv/first/allarea``."""
        return self.call("mv/first/allarea", limit=limit)
