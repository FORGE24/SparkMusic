"""Search endpoints."""
from __future__ import annotations

from typing import Any

from .base import ApiMixin

__all__ = ["SearchApi", "SEARCH_TYPES"]

SEARCH_TYPES = {
    "song": 1,
    "album": 10,
    "artist": 100,
    "playlist": 1000,
    "user": 1002,
    "mv": 1004,
    "lyric": 1006,
    "radio": 1009,
    "video": 1014,
    "mlog": 1018,
}


class SearchApi(ApiMixin):
    """Unified search, suggestions and resource-specific search pages."""

    def search(
        self,
        keyword: str,
        type_: int | str = 1,
        limit: int = 30,
        offset: int = 0,
        route: str = "v1/search/get",
        **extra: Any,
    ) -> dict[str, Any]:
        """Search.  Route: ``v1/search/get`` (inferred from the string pool).

        ``s`` and ``keyword`` are both sent for compatibility with the two
        generations of the endpoint.  ``type_`` may be an int or a name from
        :data:`SEARCH_TYPES`.
        """
        if isinstance(type_, str):
            type_ = SEARCH_TYPES.get(type_, type_)
        return self.call(
            route,
            s=keyword,
            keyword=keyword,
            type=type_,
            limit=limit,
            offset=offset,
            total=self._flag(True),
            **extra,
        )

    def search_songs(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Songs (type 1)."""
        return self.search(keyword, 1, limit, offset, **extra)

    def search_albums(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Albums (type 10)."""
        return self.search(keyword, 10, limit, offset, **extra)

    def search_artists(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Artists (type 100)."""
        return self.search(keyword, 100, limit, offset, **extra)

    def search_playlists(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Playlists (type 1000)."""
        return self.search(keyword, 1000, limit, offset, **extra)

    def search_users(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Users (type 1002)."""
        return self.search(keyword, 1002, limit, offset, **extra)

    def search_mvs(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """MVs (type 1004)."""
        return self.search(keyword, 1004, limit, offset, **extra)

    def search_lyrics(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Lyrics (type 1006)."""
        return self.search(keyword, 1006, limit, offset, **extra)

    def search_radios(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Radio stations (type 1009)."""
        return self.search(keyword, 1009, limit, offset, **extra)

    def search_videos(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Videos (type 1014)."""
        return self.search(keyword, 1014, limit, offset, **extra)

    def search_mlog(self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any):
        """Mlog posts.  Route: ``search/mlog/get``."""
        return self.call(
            "search/mlog/get", keyword=keyword, limit=limit, offset=offset, **extra
        )

    def search_complex(
        self,
        keyword: str,
        limit: int = 30,
        offset: int = 0,
        page: int = 1,
        scene: str = "normal",
        channel: str = "netease",
        cursor: int | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Modern multi-block search.  Route: ``search/complex/page``."""
        return self.call(
            "search/complex/page",
            keyword=keyword,
            limit=limit,
            offset=offset,
            page=page,
            scene=scene,
            channel=channel,
            cursor=cursor,
            newStyle=True,
            **extra,
        )

    def search_suggest(self, keyword: str, limit: int = 10, **extra: Any) -> dict[str, Any]:
        """Search suggestions.  Route: ``search/suggest/keyword``."""
        return self.call(
            "search/suggest/keyword", s=keyword, limit=limit, type=1, **extra
        )

    def search_suggest_get(self, keyword: str, **extra: Any) -> dict[str, Any]:
        """Suggestion detail.  Route: ``search/suggest/keyword/get``."""
        return self.call("search/suggest/keyword/get", keyword=keyword, **extra)

    def search_default_keyword(self) -> dict[str, Any]:
        """Default/placeholder keyword.  Route: ``search/defaultkeyword/get``."""
        return self.call("search/defaultkeyword/get")

    def search_default_keywords(
        self,
        position_code: str = "search",
        limit: int = 10,
        type_: int = 1,
        **extra: Any,
    ) -> dict[str, Any]:
        """Default keyword tray.  Route: ``search/default/keyword/list``."""
        return self.call(
            "search/default/keyword/list",
            positionCode=position_code,
            limit=limit,
            type=type_,
            **extra,
        )

    def search_special_keyword(self, **extra: Any) -> dict[str, Any]:
        """Special keyword card.  Route: ``search/specialkeyword/get``."""
        return self.call("search/specialkeyword/get", **extra)

    def search_resource_lyric(
        self, keyword: str, limit: int = 30, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Lyric search page.  Route: ``search/resource/lyric``."""
        return self.call(
            "search/resource/lyric", keyword=keyword, limit=limit, offset=offset, **extra
        )

    def search_total_block(
        self, keyword: str, block_code: str = "", limit: int = 30, **extra: Any
    ) -> dict[str, Any]:
        """Search block totals.  Route: ``search/total/block/get``."""
        return self.call(
            "search/total/block/get",
            keyword=keyword,
            blockCode=block_code,
            limit=limit,
            **extra,
        )

    def search_video_tag(self, keyword: str, **extra: Any) -> dict[str, Any]:
        """Video tag suggestions.  Route: ``search/video/tag/get``."""
        return self.call("search/video/tag/get", keyword=keyword, **extra)

    def search_match(self, type_: int, result: str, song_data: str, **extra: Any) -> dict[str, Any]:
        """Local-song match.  Route: ``search/match/new``."""
        return self.call(
            "search/match/new", type=type_, result=result, songdata=song_data, **extra
        )
