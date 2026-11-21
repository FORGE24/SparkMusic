"""Recommendations, personalized blocks, similar-resource discovery and toplists."""
from __future__ import annotations

from typing import Any

from .base import ApiMixin

__all__ = ["RecommendApi", "ToplistApi", "PersonalizedApi"]


class RecommendApi(ApiMixin):
    """Daily recommendations, new songs and similar resources."""

    def recommend_songs(self) -> dict[str, Any]:
        """Daily recommended songs.  Route: ``v3/discovery/recommend/songs``."""
        return self.call("v3/discovery/recommend/songs")

    def recommend_songs_v2(self) -> dict[str, Any]:
        """Recommended songs (v2).  Route: ``v2/discovery/recommend/songs``."""
        return self.call("v2/discovery/recommend/songs")

    def recommend_new_songs(self, area_id: int = 0) -> dict[str, Any]:
        """New-song recommendations.  Route: ``v2/discovery/new/songs``."""
        return self.call("v2/discovery/new/songs", areaId=area_id)

    def recommend_dislike(
        self,
        res_type: str,
        res_id: str | int,
        scene_type: str = "",
        order_id: str = "",
        ext_param: str = "",
    ) -> dict[str, Any]:
        """Dislike a recommendation.  Route: ``v2/discovery/recommend/dislike``."""
        return self.call(
            "v2/discovery/recommend/dislike",
            resType=res_type,
            resId=res_id,
            sceneType=scene_type,
            orderId=order_id,
            extParam=ext_param,
        )

    def recommend_history_recent(self) -> dict[str, Any]:
        """Recent recommendation history.  Route: ``discovery/recommend/songs/history/recent``."""
        return self.call("discovery/recommend/songs/history/recent")

    def recommend_history_detail(self) -> dict[str, Any]:
        """Recommendation history detail.  Route: ``discovery/recommend/songs/history/detail``."""
        return self.call("discovery/recommend/songs/history/detail")

    def recommend_new_albums(self, year: int, month: int) -> dict[str, Any]:
        """New albums by month.  Route: ``discovery/new/albums``."""
        return self.call("discovery/new/albums", year=year, month=month)

    def simi_song(self, song_id: str | int, limit: int = 50) -> dict[str, Any]:
        """Similar songs.  Route: ``v1/discovery/simiSong``."""
        return self.call("v1/discovery/simiSong", songid=song_id, limit=limit)

    def simi_playlist(self, playlist_id: str | int, limit: int = 50) -> dict[str, Any]:
        """Similar playlists.  Route: ``discovery/simiPlaylist``."""
        return self.call("discovery/simiPlaylist", id=playlist_id, limit=limit)

    def simi_user(self, user_id: str | int, limit: int = 50) -> dict[str, Any]:
        """Similar users.  Route: ``discovery/simiUser``."""
        return self.call("discovery/simiUser", id=user_id, limit=limit)

    def simi_artist(self, artist_id: str | int, limit: int = 20) -> dict[str, Any]:
        """Similar artists.  Route: ``v1/similar/artist/get``."""
        return self.call("v1/similar/artist/get", artistId=artist_id, limit=limit)

    def discovery_playlist_talent(self) -> dict[str, Any]:
        """Playlist talent list.  Route: ``discovery/playlistTalentList``."""
        return self.call("discovery/playlistTalentList")

    def discovery_top_new_users(self) -> dict[str, Any]:
        """Top new users.  Route: ``discovery/topNewUserList``."""
        return self.call("discovery/topNewUserList")


class PersonalizedApi(ApiMixin):
    """Personalized home blocks."""

    def personalized_mv(
        self,
        limit: int = 10,
        offset: int = 0,
        resolution: int = 1080,
        need_url: bool = True,
    ) -> dict[str, Any]:
        """Personalized MVs.  Route: ``personalized/mv``."""
        return self.call(
            "personalized/mv",
            limit=limit,
            offset=offset,
            resolution=resolution,
            needUrl=self._flag(need_url),
        )

    def personalized_playlist_tag_rcmd(self) -> dict[str, Any]:
        """Recommended playlist tags.  Route: ``personalized/playlist/tag/rcmd``."""
        return self.call("personalized/playlist/tag/rcmd")

    def personalized_dislike_reason(self) -> dict[str, Any]:
        """Dislike reasons.  Route: ``personalized/dislike/reason``."""
        return self.call("personalized/dislike/reason")


class ToplistApi(ApiMixin):
    """Charts and official playlist ids."""

    def toplist_detail(self, **extra: Any) -> dict[str, Any]:
        """Chart detail.  Route: ``toplist/detail/v2``."""
        return self.call("toplist/detail/v2", **extra)

    def toplist_artist(self, type_: int = 1) -> dict[str, Any]:
        """Artist chart.  Route: ``toplist/artist``."""
        return self.call("toplist/artist", type=type_)

    def toplist_default_pics(self) -> dict[str, Any]:
        """Chart cover pictures.  Route: ``toplist/default/pics/v2``."""
        return self.call("toplist/default/pics/v2")

    def toplist_official_playlists(self) -> dict[str, Any]:
        """Official playlist ids.  Route: ``playlist/official/ids/get``."""
        return self.call("playlist/official/ids/get")

    def reward_toplist(
        self, type_: str = "", all_: bool = False, limit: int = 20, offset: int = 0
    ) -> dict[str, Any]:
        """Reward chart.  Route: ``reward/resource/toplist``."""
        return self.call(
            "reward/resource/toplist",
            type=type_,
            all=self._flag(all_),
            limit=limit,
            offset=offset,
        )
