"""Settings, abuse reports, feedback and the 'listen together' feature."""
from __future__ import annotations

from typing import Any

from .base import ApiMixin

__all__ = ["SettingApi", "ReportApi", "FeedbackApi", "ListenTogetherApi", "MineApi"]


class SettingApi(ApiMixin):
    """App setting endpoints."""

    def setting_module_tags(self) -> dict[str, Any]:
        """User module tags.  Route: ``setting/user/module/tags``."""
        return self.call("setting/user/module/tags")

    def setting_developer(self, **extra: Any) -> dict[str, Any]:
        """Developer settings.  Route: ``setting/developer``."""
        return self.call("setting/developer", **extra)

    def setting_float_permission(self, **extra: Any) -> dict[str, Any]:
        """Floating-window permission state.  Route: ``setting/floatpermission``."""
        return self.call("setting/floatpermission", **extra)

    def setting_lockscreen_permission(self, **extra: Any) -> dict[str, Any]:
        """Lockscreen permission state.  Route: ``setting/lockscreenpermission``."""
        return self.call("setting/lockscreenpermission", **extra)

    def setting_widget(self, **extra: Any) -> dict[str, Any]:
        """Widget settings.  Route: ``setting/widgetsetting``."""
        return self.call("setting/widgetsetting", **extra)


class ReportApi(ApiMixin):
    """Content/user abuse reports."""

    def report_types(self) -> dict[str, Any]:
        """Available report reasons.  Route: ``report/type/get``."""
        return self.call("report/type/get")

    def report_event(
        self,
        event_id: str | int,
        reason: str,
        report_type: int = 1,
        user_id: str | int = "",
    ) -> dict[str, Any]:
        """Report an event.  Route: ``report/reportevent``."""
        return self.call(
            "report/reportevent",
            id=event_id,
            userid=user_id,
            reason=reason,
            reportType=report_type,
        )

    def report_comment(
        self,
        thread_id: str,
        comment_id: str | int,
        reason: str,
        report_type: int = 1,
        combine_id: str = "",
        type_: int = 1,
    ) -> dict[str, Any]:
        """Report a comment.  Route: ``report/reportcomment``."""
        return self.call(
            "report/reportcomment",
            threadId=thread_id,
            commentId=comment_id,
            combindId=combine_id,
            type=type_,
            reason=reason,
            reportType=report_type,
        )

    def report_mlog(
        self, mlog_id: str | int, reason: str, report_type: int = 1
    ) -> dict[str, Any]:
        """Report an mlog.  Route: ``report/reportmlog``."""
        return self.call("report/reportmlog", id=mlog_id, reason=reason, reportType=report_type)

    def report_message(
        self,
        user_id: str | int,
        reason: str,
        report_type: int = 1,
        msg_id: str | int = "",
    ) -> dict[str, Any]:
        """Report a private message.  Route: ``report/reportmsg``."""
        return self.call(
            "report/reportmsg",
            userid=user_id,
            reason=reason,
            reportType=report_type,
            msgId=msg_id,
        )

    def report_message_user(
        self, user_id: str | int, reason: str, report_type: int = 1
    ) -> dict[str, Any]:
        """Report a message user.  Route: ``report/msg/user``."""
        return self.call(
            "report/msg/user", userid=user_id, reason=reason, reportType=report_type
        )

    def report_resource(
        self,
        resource_type: str | int,
        resource_id: str | int,
        reason: str,
        report_type: int = 1,
    ) -> dict[str, Any]:
        """Report a generic resource.  Route: ``report/reportresource``."""
        return self.call(
            "report/reportresource",
            resourceType=resource_type,
            resourceId=resource_id,
            reason=reason,
            reportType=report_type,
        )

    def report_user(
        self, user_id: str | int, reason: str, report_type: int = 1
    ) -> dict[str, Any]:
        """Report a user.  Route: ``report/reportuser``."""
        return self.call(
            "report/reportuser", userid=user_id, reason=reason, reportType=report_type
        )


class FeedbackApi(ApiMixin):
    """Feedback endpoints."""

    def feedback_lyric(
        self,
        song_id: str | int,
        error_type: int,
        lyric_version: int = 0,
        x_info: str = "",
        **extra: Any,
    ) -> dict[str, Any]:
        """Report a lyric error.  Route: ``v1/feedback/lyric``."""
        return self.call(
            "v1/feedback/lyric",
            errorType=error_type,
            lyricVersion=lyric_version,
            songId=song_id,
            xInfo=x_info,
            **extra,
        )

    def feedback_log(self, **extra: Any) -> dict[str, Any]:
        """Upload a log.  Route: ``feedback/log/android``."""
        return self.call("feedback/log/android", **extra)


class ListenTogetherApi(ApiMixin):
    """'Listen together' social listening endpoints.

    The feature has ~70 recovered routes.  Common flows have helpers; anything
    else can be reached through :meth:`together`.
    """

    def together(self, route: str, **params: Any) -> dict[str, Any]:
        """Call any ``listen/together/...`` route by its suffix."""
        if not route.startswith("listen/together/"):
            route = "listen/together/" + route.lstrip("/")
        return self.call(route, **params)

    def together_status(self) -> dict[str, Any]:
        """Current listen-together state.  Route: ``listen/together/status/get``."""
        return self.call("listen/together/status/get")

    def together_heartbeat(self, **extra: Any) -> dict[str, Any]:
        """Heartbeat.  Route: ``listen/together/heartbeat``."""
        return self.call("listen/together/heartbeat", **extra)

    def together_room_create(self, **extra: Any) -> dict[str, Any]:
        """Create a room.  Route: ``listen/together/room/create``."""
        return self.call("listen/together/room/create", **extra)

    def together_room_check(self, **extra: Any) -> dict[str, Any]:
        """Check a room.  Route: ``listen/together/room/check``."""
        return self.call("listen/together/room/check", **extra)

    def together_room_songs(self, **extra: Any) -> dict[str, Any]:
        """Room song list.  Route: ``listen/together/room/songs/list``."""
        return self.call("listen/together/room/songs/list", **extra)

    def together_sync_playlist(self, **extra: Any) -> dict[str, Any]:
        """Synced playlist.  Route: ``listen/together/sync/playlist/get``."""
        return self.call("listen/together/sync/playlist/get", **extra)

    def together_play_report(self, **extra: Any) -> dict[str, Any]:
        """Report playback.  Route: ``listen/together/play/command/report``."""
        return self.call("listen/together/play/command/report", **extra)

    def together_invite(
        self, user_id: str | int, **extra: Any
    ) -> dict[str, Any]:
        """Invite a user.  Route: ``listen/together/invite/message/send``."""
        return self.call(
            "listen/together/invite/message/send", userId=user_id, **extra
        )

    def together_invitation_accept(self, **extra: Any) -> dict[str, Any]:
        """Accept an invitation.  Route: ``listen/together/play/invitation/accept``."""
        return self.call("listen/together/play/invitation/accept", **extra)

    def together_invitation_reject(self, **extra: Any) -> dict[str, Any]:
        """Reject an invitation.  Route: ``listen/together/invitation/reject``."""
        return self.call("listen/together/invitation/reject", **extra)

    def together_end(self, **extra: Any) -> dict[str, Any]:
        """End a session.  Route: ``listen/together/end/v2``."""
        return self.call("listen/together/end/v2", **extra)

    def together_song_match_start(self, **extra: Any) -> dict[str, Any]:
        """Start song matching.  Route: ``listen/together/song/match/start``."""
        return self.call("listen/together/song/match/start", **extra)

    def together_song_match_ack(self, **extra: Any) -> dict[str, Any]:
        """Acknowledge song matching.  Route: ``listen/together/song/match/ack``."""
        return self.call("listen/together/song/match/ack", **extra)

    def together_song_match_cancel(self, **extra: Any) -> dict[str, Any]:
        """Cancel song matching.  Route: ``listen/together/song/match/cancel``."""
        return self.call("listen/together/song/match/cancel", **extra)

    def together_user_state_get(self) -> dict[str, Any]:
        """User state.  Route: ``listen/together/user/state/get``."""
        return self.call("listen/together/user/state/get")

    def together_user_state_set(self, **extra: Any) -> dict[str, Any]:
        """Update user state.  Route: ``listen/together/user/state/set``."""
        return self.call("listen/together/user/state/set", **extra)

    def together_emoticons(self) -> dict[str, Any]:
        """Emoticon list.  Route: ``listen/together/emoticon/get``."""
        return self.call("listen/together/emoticon/get")


class MineApi(ApiMixin):
    """'Mine' tab blocks."""

    def mine_collect_header(self) -> dict[str, Any]:
        """Collect header.  Route: ``mine/collect/header/info``."""
        return self.call("mine/collect/header/info")

    def mine_artist_award(self, song_id: str | int) -> dict[str, Any]:
        """Artist award info for a song.

        Route: ``song/more/artist/award/info/query``.  9.6.30 dropped the older
        ``mine/collect/artist/award/info/query`` spelling; this one takes the
        same ``songId`` parameter.
        """
        return self.call("song/more/artist/award/info/query", songId=song_id)

    def mine_latest_resource_report(self, **extra: Any) -> dict[str, Any]:
        """Latest resource report.  Route: ``mine/user/latest/resource/report``."""
        return self.call("mine/user/latest/resource/report", **extra)

    def mine_page_prompt(self) -> dict[str, Any]:
        """Page prompt.  Route: ``mine/page/prompt/get``."""
        return self.call("mine/page/prompt/get")

    def mine_tab_counts(self) -> dict[str, Any]:
        """Tab counters.  Route: ``mine/page/tab/nums/count``."""
        return self.call("mine/page/tab/nums/count")

    def mine_redpoint(self) -> dict[str, Any]:
        """Applet red point.  Route: ``mine/applet/redpoint``."""
        return self.call("mine/applet/redpoint")

    def mine_redpoint_click(self, **extra: Any) -> dict[str, Any]:
        """Applet red point click.  Route: ``mine/applet/redpoint/click``."""
        return self.call("mine/applet/redpoint/click", **extra)
