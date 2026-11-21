"""Events, mlog (music logs), topics and private messages."""
from __future__ import annotations

from typing import Any, Iterable

from .base import ApiMixin

__all__ = ["EventApi", "MlogApi", "TopicApi", "MsgApi"]


class EventApi(ApiMixin):
    """Social event/feed endpoints."""

    def user_events(
        self, user_id: str | int, limit: int = 20, time: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Events published by a user.  Route: ``event/get/{userId}``."""
        return self.call(
            f"event/get/{user_id}", userId=user_id, limit=limit, time=time, **extra
        )

    def event_detail(
        self, event_id: str | int, user_id: str | int | None = None
    ) -> dict[str, Any]:
        """Event detail.  Route: ``event/detail/get/v1``."""
        return self.call("event/detail/get/v1", id=event_id, userId=user_id)

    def event_forward(
        self, event_id: str | int, forwards: int = 1, **extra: Any
    ) -> dict[str, Any]:
        """Forward an event.  Route: ``event/forward``."""
        return self.call("event/forward", id=event_id, forwards=forwards, **extra)

    def event_forward_list(self) -> dict[str, Any]:
        """Event forward list.  Route: ``event/forwardlist``."""
        return self.call("event/forwardlist")

    def event_delete(
        self, event_id: str | int, delete_strategy: int = 0
    ) -> dict[str, Any]:
        """Delete an event.  Route: ``event/delete``."""
        return self.call("event/delete", id=event_id, deleteStrategy=delete_strategy)

    def event_top_get(self, user_id: str | int) -> dict[str, Any]:
        """Pinned events.  Route: ``event/top/get``."""
        return self.call("event/top/get", userId=user_id)

    def event_top_add(self, event_id: str | int, status: int = 1) -> dict[str, Any]:
        """Pin an event.  Route: ``event/top/add``."""
        return self.call("event/top/add", eventId=event_id, topStatus=status)

    def event_top_delete(self, event_id: str | int, status: int = 0) -> dict[str, Any]:
        """Unpin an event.  Route: ``event/top/delete``."""
        return self.call("event/top/delete", eventId=event_id, topStatus=status)

    def event_privacy(self, event_id: str | int, privacy: int) -> dict[str, Any]:
        """Change event privacy.  Route: ``event/privacy/op``."""
        return self.call("event/privacy/op", eventId=event_id, privacy=privacy)

    def event_rcmd_topic_list(self, thread_id: str, source: str = "") -> dict[str, Any]:
        """Recommended topics for an event.  Route: ``event/rcmd/topic/list``."""
        return self.call("event/rcmd/topic/list", threadId=thread_id, source=source)

    def event_rcmd_reject(self, event_id: str | int) -> dict[str, Any]:
        """Reject a recommended event.  Route: ``event/rcmd/reject``."""
        return self.call("event/rcmd/reject", id=event_id)

    def event_discuss_detail(self, **extra: Any) -> dict[str, Any]:
        """Event discussion detail.  Route: ``event/discuss/detail/get``."""
        return self.call("event/discuss/detail/get", **extra)

    def event_discuss_publish(self, **params: Any) -> dict[str, Any]:
        """Publish an event discussion.  Route: ``event/discuss/publish``.

        The recovered method accepts a large parameter set; pass it through.
        """
        return self.call("event/discuss/publish", **params)

    def event_join_notice(self) -> dict[str, Any]:
        """Event join notice.  Route: ``event/board/join/notice/get``."""
        return self.call("event/board/join/notice/get")

    def event_user_permission(self) -> dict[str, Any]:
        """Event permissions.  Route: ``event/user/permission``."""
        return self.call("event/user/permission")

    def event_user_rcmd(self, **extra: Any) -> dict[str, Any]:
        """Recommended users/events.  Route: ``event/user/rcmd/v3``."""
        return self.call("event/user/rcmd/v3", **extra)

    def event_square_feed(self, cursor: int | None = None, **extra: Any) -> dict[str, Any]:
        """Event square feed.  Route: ``event/square/feed/get``."""
        return self.call("event/square/feed/get", cursor=cursor, **extra)

    def event_song_share_check(self, **extra: Any) -> dict[str, Any]:
        """Song-share eligibility.  Route: ``event/song/share/check``."""
        return self.call("event/song/share/check", **extra)


class MlogApi(ApiMixin):
    """Mlog (music log / video note) endpoints."""

    def mlog_detail(self, mlog_id: str | int, **extra: Any) -> dict[str, Any]:
        """Mlog detail.  Route: ``mlog/detail``."""
        return self.call("mlog/detail", id=mlog_id, **extra)

    def mlog_detail_v1(self, mlog_id: str | int, **extra: Any) -> dict[str, Any]:
        """Mlog detail (v1).  Route: ``mlog/detail/v1``."""
        return self.call("mlog/detail/v1", id=mlog_id, **extra)

    def mlog_base(self, mlog_id: str | int, **extra: Any) -> dict[str, Any]:
        """Mlog base info.  Route: ``mlog/base``."""
        return self.call("mlog/base", id=mlog_id, **extra)

    def mlog_box_detail(self, mlog_id: str | int, **extra: Any) -> dict[str, Any]:
        """Mlog box detail.  Route: ``mlog/box/detail``."""
        return self.call("mlog/box/detail", id=mlog_id, **extra)

    def mlog_rcmd(self, version: int = 3) -> dict[str, Any]:
        """Recommended mlogs.  Routes: ``mlog/rcmd/v3`` / ``v2``."""
        return self.call("mlog/rcmd/v3" if version >= 3 else "mlog/rcmd/v2")

    def mlog_feed(self, **extra: Any) -> dict[str, Any]:
        """Mlog feed.  Route: ``mlog/rcmd/feed/list``."""
        return self.call("mlog/rcmd/feed/list", **extra)

    def mlog_feed_box(self, **extra: Any) -> dict[str, Any]:
        """Mlog feed box.  Route: ``mlog/rcmd/feed/list/box``."""
        return self.call("mlog/rcmd/feed/list/box", **extra)

    def mlog_homepage_rcmd(self, **extra: Any) -> dict[str, Any]:
        """Homepage mlog recommendations.  Route: ``mlog/homepage/rec/get``."""
        return self.call("mlog/homepage/rec/get", **extra)

    def mlog_mymlog(self, user_id: str | int, **extra: Any) -> dict[str, Any]:
        """A user's mlogs.  Route: ``mlog/mymlog/get/v1``."""
        return self.call("mlog/mymlog/get/v1", userId=user_id, **extra)

    def mlog_delete(self, mlog_id: str | int) -> dict[str, Any]:
        """Delete an mlog.  Route: ``mlog/delete``."""
        return self.call("mlog/delete", id=mlog_id)

    def mlog_resource_collect(
        self, resource_id: str | int, type_: int | str = 1
    ) -> dict[str, Any]:
        """Collect a resource in mlog.  Route: ``mlog/resource/collect``."""
        return self.call("mlog/resource/collect", id=resource_id, type=type_)

    def mlog_resource_uncollect(
        self, resource_id: str | int, type_: int | str = 1
    ) -> dict[str, Any]:
        """Uncollect.  Route: ``mlog/resource/uncollect``."""
        return self.call("mlog/resource/uncollect", id=resource_id, type=type_)

    def mlog_song_url(self, mlog_id: str | int, **extra: Any) -> dict[str, Any]:
        """Song URL used in an mlog.  Route: ``mlog/song/url``."""
        return self.call("mlog/song/url", id=mlog_id, **extra)

    def mlog_video_url(self, mlog_id: str | int, **extra: Any) -> dict[str, Any]:
        """Video URL used in an mlog.  Route: ``mlog/video/url``."""
        return self.call("mlog/video/url", id=mlog_id, **extra)

    def mlog_talk_create(self, name: str, **extra: Any) -> dict[str, Any]:
        """Create a talk.  Route: ``mlog/talk/create``."""
        return self.call("mlog/talk/create", name=name, **extra)

    def mlog_talk_search(
        self,
        keywords: str,
        page: int = 1,
        limit: int = 20,
        type_: int = 1,
        status: int = 0,
        sort_prop: str = "",
    ) -> dict[str, Any]:
        """Search talks.  Route: ``mlog/talk/search``."""
        return self.call(
            "mlog/talk/search",
            keywords=keywords,
            page=page,
            limit=limit,
            type=type_,
            status=status,
            sortProp=sort_prop,
        )

    def mlog_music_search(
        self, keyword: str, page: int = 1, limit: int = 20, scene: str = ""
    ) -> dict[str, Any]:
        """Search music for mlog.  Route: ``mlog/music/search/v1``."""
        return self.call(
            "mlog/music/search/v1", keyword=keyword, page=page, limit=limit, scene=scene
        )

    def mlog_music_rcmd(self, scene: str = "") -> dict[str, Any]:
        """Recommended music for mlog.  Route: ``mlog/music/rcmd/v1``."""
        return self.call("mlog/music/rcmd/v1", scene=scene)

    def mlog_classification_song(
        self, scene: str = "", class_id: str | int = "", page: int = 1, limit: int = 20
    ) -> dict[str, Any]:
        """Classified songs for mlog.  Route: ``mlog/classification/song/v1``."""
        return self.call(
            "mlog/classification/song/v1",
            scene=scene,
            classId=class_id,
            page=page,
            limit=limit,
        )

    def mlog_playlist_song(
        self, playlist_id: str | int, scene: str = "", page: int = 1, limit: int = 20
    ) -> dict[str, Any]:
        """Playlist songs for mlog.  Route: ``mlog/playlist/song/v1``."""
        return self.call(
            "mlog/playlist/song/v1",
            playlistId=playlist_id,
            scene=scene,
            page=page,
            limit=limit,
        )

    def mlog_songmlog(
        self,
        song_id: str | int,
        resource: str = "",
        resource_mlog_id: str | int = "",
        limit: int = 20,
        offset: int = 0,
        time: int = 0,
        order: str = "bytime",
    ) -> dict[str, Any]:
        """Mlogs containing a song.  Routes: ``mlog/songmlog/by{time,score}/get/v2``."""
        route = (
            "mlog/songmlog/bysocre/get/v2"
            if order == "score"
            else "mlog/songmlog/bytime/get/v2"
        )
        return self.call(
            route,
            songId=song_id,
            resource=resource,
            resourceMlogId=resource_mlog_id,
            limit=limit,
            offset=offset,
            time=time,
        )

    def mlog_aggregation_title(self, aggregation_id: str | int) -> dict[str, Any]:
        """Aggregation title.  Route: ``mlog/aggregation/title/get``."""
        return self.call("mlog/aggregation/title/get", id=aggregation_id, v=1)

    def mlog_aggregation_activities(self, aggregation_id: str | int) -> dict[str, Any]:
        """Aggregation activities.  Route: ``mlog/aggregation/activities/get``."""
        return self.call("mlog/aggregation/activities/get", id=aggregation_id, v=1)

    def mlog_mycollect_bytime(self) -> dict[str, Any]:
        """Collected mlogs by time.  Route: ``mlog/mycollect/bytime/get``."""
        return self.call("mlog/mycollect/bytime/get")

    def mlog_mycollect_count(self) -> dict[str, Any]:
        """Collected mlog count.  Route: ``mlog/mycollect/count/get``."""
        return self.call("mlog/mycollect/count/get")

    def mlog_mylike_bytime(self) -> dict[str, Any]:
        """Liked mlogs by time.  Route: ``mlog/mylike/bytime/get/v1``."""
        return self.call("mlog/mylike/bytime/get/v1")

    def mlog_playlist_cards(self, **extra: Any) -> dict[str, Any]:
        """Mlog playlist cards.  Route: ``mlog/playlist/cards/get``."""
        return self.call("mlog/playlist/cards/get", **extra)

    def mlog_vinyl_story_list(self, **extra: Any) -> dict[str, Any]:
        """Vinyl story list.  Route: ``mlog/vinyl/story/list``."""
        return self.call("mlog/vinyl/story/list", **extra)

    def mlog_publish_config(self) -> dict[str, Any]:
        """Publish configuration.  Route: ``mlog/publish/config``."""
        return self.call("mlog/publish/config")

    def mlog_publish_async(self, template_id: str | int, **params: Any) -> dict[str, Any]:
        """Publish an mlog asynchronously.  Route: ``mlog/publish/async``."""
        return self.call("mlog/publish/async", templateId=template_id, **params)

    def mlog_mix_status_get(self, encrypted_mlog_id: str) -> dict[str, Any]:
        """Mix status.  Route: ``mlog/mix/status/get``."""
        return self.call("mlog/mix/status/get", encMlogId=encrypted_mlog_id)

    def mlog_mix_status_update(
        self, encrypted_mlog_id: str, mix_status: int
    ) -> dict[str, Any]:
        """Update mix status.  Route: ``mlog/mix/status/update``."""
        return self.call(
            "mlog/mix/status/update", encMlogId=encrypted_mlog_id, mixStatus=mix_status
        )


class TopicApi(ApiMixin):
    """Topic endpoints."""

    def topic_hot(self) -> dict[str, Any]:
        """Hot topics.  Route: ``topic/hot``."""
        return self.call("topic/hot")

    def topic_all(self, series_id: str | int, limit: int = 20, offset: int = 0):
        """Topics in a series.  Route: ``topic/all``."""
        return self.call("topic/all", seriesId=series_id, limit=limit, offset=offset)

    def topic_category_hot(
        self, category_id: str | int, limit: int = 20, offset: int = 0, pubtime: int = 0
    ) -> dict[str, Any]:
        """Hot topics by category.  Route: ``topic/category/hot/list``."""
        return self.call(
            "topic/category/hot/list",
            categoryid=category_id,
            limit=limit,
            offset=offset,
            pubtime=pubtime,
        )

    def topic_category_time(
        self, category_id: str | int, limit: int = 20, offset: int = 0, pubtime: int = 0
    ) -> dict[str, Any]:
        """Newest topics by category.  Route: ``topic/category/time/list``."""
        return self.call(
            "topic/category/time/list",
            categoryid=category_id,
            limit=limit,
            offset=offset,
            pubtime=pubtime,
        )

    def topic_index_category(self) -> dict[str, Any]:
        """Topic index categories.  Route: ``topic/index/category/list``."""
        return self.call("topic/index/category/list")

    def topic_selected(self, limit: int = 20, pubtime: int = 0) -> dict[str, Any]:
        """Selected topics.  Route: ``topic/selected/list``."""
        return self.call("topic/selected/list", limit=limit, pubtime=pubtime)

    def topic_series_byuser(self, user_id: str | int) -> dict[str, Any]:
        """Topic series by user.  Route: ``topic/series/byuser``."""
        return self.call("topic/series/byuser", userId=user_id)

    def topic_sub(self, topic_id: str | int) -> dict[str, Any]:
        """Subscribe.  Route: ``topic/sub``."""
        return self.call("topic/sub", id=topic_id)

    def topic_unsub(self, topic_id: str | int) -> dict[str, Any]:
        """Unsubscribe.  Route: ``topic/unsub``."""
        return self.call("topic/unsub", id=topic_id)

    def topic_sublist(self) -> dict[str, Any]:
        """Subscribed topics.  Route: ``topic/sublist``."""
        return self.call("topic/sublist")

    def topic_thread(
        self, thread_id: str, limit: int = 20, offset: int = 0
    ) -> dict[str, Any]:
        """Topics in a thread.  Route: ``topic/thread``."""
        return self.call("topic/thread", threadId=thread_id, limit=limit, offset=offset)


class MsgApi(ApiMixin):
    """Private messages and notifications."""

    def msg_recent_contacts(self) -> dict[str, Any]:
        """Recent conversations.  Route: ``msg/recentcontact/get``."""
        return self.call("msg/recentcontact/get")

    def msg_private_send(
        self,
        user_ids: Iterable[str | int] | str,
        msg: str,
        type_: int = 1,
        **extra: Any,
    ) -> dict[str, Any]:
        """Send a private message.  Route: ``msg/private/send``."""
        return self.call(
            "msg/private/send",
            userIds=self._ids(user_ids),
            msg=msg,
            type=type_,
            **extra,
        )

    def msg_notice_delete(self, notice_id: str | int) -> dict[str, Any]:
        """Delete a notice.  Route: ``msg/notice/delete``."""
        return self.call("msg/notice/delete", id=notice_id)

    def msg_count_clear(self) -> dict[str, Any]:
        """Clear message counts.  Route: ``msg/count/clear``."""
        return self.call("msg/count/clear")

    def msg_private_notice_history(self, **extra: Any) -> dict[str, Any]:
        """Notice account history.  Route: ``msg/private/noticeaccount/history``."""
        return self.call("msg/private/noticeaccount/history", **extra)
