"""User profile, social graph and user-scoped resources."""
from __future__ import annotations

from typing import Any, Iterable

from .base import ApiMixin

__all__ = ["UserApi"]


class UserApi(ApiMixin):
    """User endpoints recovered from 9.6.30, plus a few classic fallbacks."""

    def user_detail(self, uid: str | int) -> dict[str, Any]:
        """User profile.  Route: ``v1/user/detail/{uid}`` (templated)."""
        return self.call(f"v1/user/detail/{uid}")

    def user_info(self) -> dict[str, Any]:
        """Full profile for the logged-in user (``v1/user/info``)."""
        return self.call("v1/user/info")

    def user_current_profile(self) -> dict[str, Any]:
        """Current profile shortcut (``user/current/profile``, inferred route)."""
        return self.call("user/current/profile")

    def user_playlists(
        self,
        uid: str | int,
        limit: int = 1000,
        offset: int = 0,
        include_video: bool = False,
        **extra: Any,
    ) -> dict[str, Any]:
        """Playlists owned/collected by a user.  Route: ``user/playlist``."""
        return self.call(
            "user/playlist",
            uid=uid,
            limit=limit,
            offset=offset,
            includeVideo=self._flag(include_video),
            **extra,
        )

    def user_playlists_v2(
        self,
        uid: str | int,
        limit: int = 1000,
        offset: int = 0,
        include_video: bool = False,
        include_share_status: bool = False,
        sort_type: int | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Extended playlist listing.  Route: ``user/playlist/v2``."""
        return self.call(
            "user/playlist/v2",
            uid=uid,
            limit=limit,
            offset=offset,
            includeVideo=self._flag(include_video),
            includeShareStatus=self._flag(include_share_status),
            sortType=sort_type,
            **extra,
        )

    def user_follows(
        self,
        uid: str | int,
        offset: int = 0,
        limit: int = 30,
        order: bool = False,
    ) -> dict[str, Any]:
        """Users this user follows.  Route: ``user/getfollows/{uid}``."""
        return self.call(f"user/getfollows/{uid}", offset=offset, limit=limit, order=self._flag(order))

    def user_followers(
        self,
        uid: str | int,
        offset: int = 0,
        limit: int = 30,
        time: int = 0,
    ) -> dict[str, Any]:
        """Followers.  Classic ``/weapi/user/getfolloweds`` fallback.

        This route was not present in the 9.6.30 catalog (the app derives the
        follower list through other modules); it is included because the
        public endpoint is stable.
        """
        return self.call(
            "user/getfolloweds",
            _mode="weapi",
            userId=uid,
            offset=offset,
            limit=limit,
            time=time,
        )

    def user_follow(self, uid: str | int) -> dict[str, Any]:
        """Follow a user.  Route: ``user/follow/{uid}``."""
        return self.call(f"user/follow/{uid}")

    def user_unfollow(self, uid: str | int) -> dict[str, Any]:
        """Unfollow a user.  Route: ``user/delfollow/{uid}``."""
        return self.call(f"user/delfollow/{uid}")

    def user_bothfollow(self, uid: str | int) -> dict[str, Any]:
        """Mutual-follow check.  Route: ``user/bothfollow``."""
        return self.call("user/bothfollow", uid=uid)

    def user_mutualfollow(
        self, friend_id: str | int, time: int = 0, limit: int = 20
    ) -> dict[str, Any]:
        """Mutual follows.  Route: ``user/mutualfollow/get``."""
        return self.call(
            "user/mutualfollow/get", friendid=friend_id, time=time, limit=limit
        )

    def user_follow_users(
        self, lasttime: int = 0, limit: int = 30, order: bool = False
    ) -> dict[str, Any]:
        """Follow list with cursor.  Route: ``user/follow/users/get``."""
        return self.call(
            "user/follow/users/get", lasttime=lasttime, limit=limit, order=self._flag(order)
        )

    def user_bindings(self, uid: str | int) -> dict[str, Any]:
        """Bound third-party accounts.  Route: ``user/bindings/{uid}``."""
        return self.call(f"user/bindings/{uid}")

    def user_update_profile(
        self,
        nickname: str | None = None,
        signature: str | None = None,
        gender: int | None = None,
        province: int | None = None,
        city: int | None = None,
        birthday: int | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Update profile fields.  Route: ``user/profile/update``."""
        return self.call(
            "user/profile/update",
            nickname=nickname,
            signature=signature,
            gender=gender,
            province=province,
            city=city,
            birthday=birthday,
            **extra,
        )

    def user_remark_set(self, friend_id: str | int, remark_name: str) -> dict[str, Any]:
        """Set a contact alias.  Route: ``user/remarkname/set``."""
        return self.call(
            "user/remarkname/set", friendid=friend_id, remarkname=remark_name
        )

    def user_remark_get(
        self, friend_id: str | int, hint: str = "", alias: str = "", type_: int = 1
    ) -> dict[str, Any]:
        """Read a contact alias.  Route: ``user/remarkname/get``."""
        return self.call(
            "user/remarkname/get",
            friendid=friend_id,
            hint=hint,
            alias=alias,
            type=type_,
        )

    def user_setting(self) -> dict[str, Any]:
        """Privacy/notification settings.  Route: ``user/setting``."""
        return self.call("user/setting")

    def user_setting_update(self, **settings: Any) -> dict[str, Any]:
        """Update settings.  Route: ``user/setting/update``.

        Accepts the recovered keys, e.g. ``allowNewFollowerNotify=True``,
        ``showFMAtBottomTab=False``, ``personalizedAdRecommendSwitch=True``.
        """
        return self.call("user/setting/update", **settings)

    def user_comments(
        self,
        uid: str | int,
        limit: int = 20,
        offset: int = 0,
        scene: str = "all",
    ) -> dict[str, Any]:
        """Comments written by a user.  Route: ``v1/user/comments/{uid}``."""
        return self.call(
            f"v1/user/comments/{uid}", limit=limit, offset=offset, scene=scene
        )

    def user_sub_artist_exist(self, artist_ids: Iterable[str | int] | str) -> dict[str, Any]:
        """Subscription state for artists.  Route: ``user/sub/artist/exist``."""
        return self.call("user/sub/artist/exist", artistIds=self._ids(artist_ids))

    def user_sub_artist_get(self) -> dict[str, Any]:
        """Subscribed artists.  Route: ``user/sub/artist/get``."""
        return self.call("user/sub/artist/get")

    def user_playlist_collect(self, user_id: str | int) -> dict[str, Any]:
        """Playlists collected by a user.  Route: ``user/playlist/collect``."""
        return self.call("user/playlist/collect", userId=user_id)

    def user_playlist_favorite(self, user_id: str | int) -> dict[str, Any]:
        """Favourite playlists.  Route: ``user/playlist/favorite``."""
        return self.call("user/playlist/favorite", userId=user_id)

    def user_location(self, lat: float, lon: float) -> dict[str, Any]:
        """Report location.  Route: ``user/location``."""
        return self.call("user/location", lat=lat, lon=lon)

    def user_level(self) -> dict[str, Any]:
        """Classic ``/api/user/level`` (not in the 9.6.30 catalog)."""
        return self.call("user/level", _mode="api")

    def user_subcount(self) -> dict[str, Any]:
        """Classic ``/api/user/subcount`` (not in the 9.6.30 catalog)."""
        return self.call("user/subcount", _mode="api")

    def play_record(
        self, uid: str | int, kind: str = "song", limit: int = 100, offset: int = 0
    ) -> dict[str, Any]:
        """Listening history.  Route: ``play-record/{kind}/list``.

        ``kind`` is one of ``song``, ``album``, ``playlist``, ``djradio``,
        ``newvideo`` (the five recovered ``play-record`` routes).
        """
        if kind not in {"song", "album", "playlist", "djradio", "newvideo"}:
            raise ValueError(f"unsupported play-record kind: {kind!r}")
        return self.call(
            f"play-record/{kind}/list", uid=uid, limit=limit, offset=offset
        )
