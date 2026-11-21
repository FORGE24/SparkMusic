"""Comment resources, threads, floors and likes."""
from __future__ import annotations

from typing import Any

from .base import RESOURCE_TYPES, THREAD_PREFIXES, ApiMixin

__all__ = ["CommentApi"]


class CommentApi(ApiMixin):
    """Comment endpoints recovered from 9.6.30.

    Thread ids follow the standard NetEase scheme, e.g. ``R_SO_4_<songId>``
    for a song.  The helper methods build them for you; generic methods accept a
    raw thread id.
    """

    # ------------------------------------------------------------- internals
    @staticmethod
    def _split_thread(thread_id: str) -> tuple[int | None, str | None]:
        for name, prefix in THREAD_PREFIXES.items():
            if thread_id.startswith(prefix):
                return RESOURCE_TYPES[name], thread_id[len(prefix):]
        return None, None

    def _resource_params(
        self,
        thread_id: str,
        resource_id: str | int | None,
        resource_type: str | int | None,
    ) -> dict[str, Any]:
        parsed_type, parsed_id = self._split_thread(thread_id)
        if resource_type is None:
            resource_type = parsed_type
        elif isinstance(resource_type, str):
            resource_type = RESOURCE_TYPES.get(resource_type, resource_type)
        if resource_id is None:
            resource_id = parsed_id
        params: dict[str, Any] = {"threadId": thread_id}
        if resource_id is not None:
            params["resourceId"] = resource_id
        if resource_type is not None:
            params["resourceType"] = resource_type
        return params

    # -------------------------------------------------------------- reading
    def comment_resource(
        self,
        thread_id: str,
        resource_id: str | int | None = None,
        resource_type: str | int | None = None,
        limit: int = 20,
        offset: int = 0,
        before_time: int = 0,
        page_no: int = 1,
        hot: bool = False,
        cursor: int | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Comments of any resource.  Route: ``v1/resource/comments``."""
        params = self._resource_params(thread_id, resource_id, resource_type)
        params.update(
            self._clean(
                limit=limit,
                offset=offset,
                beforeTime=before_time,
                pageNum=page_no,
                hot=hot,
                cursor=cursor,
                **extra,
            )
        )
        return self.call("v1/resource/comments", **params)

    def comment_music(
        self, song_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Song comments (thread ``R_SO_4_<id>``)."""
        return self.comment_resource(
            self.thread_id("song", song_id),
            resource_id=song_id,
            resource_type=4,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_album(
        self, album_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Album comments (thread ``R_AL_3_<id>``)."""
        return self.comment_resource(
            self.thread_id("album", album_id),
            resource_id=album_id,
            resource_type=3,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_playlist(
        self, playlist_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Playlist comments (thread ``R_PL_2_<id>``)."""
        return self.comment_resource(
            self.thread_id("playlist", playlist_id),
            resource_id=playlist_id,
            resource_type=2,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_mv(
        self, mv_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """MV comments (thread ``R_MV_5_<id>``)."""
        return self.comment_resource(
            self.thread_id("mv", mv_id),
            resource_id=mv_id,
            resource_type=5,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_dj(
        self, program_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """DJ program comments (thread ``R_DJ_6_<id>``)."""
        return self.comment_resource(
            self.thread_id("dj", program_id),
            resource_id=program_id,
            resource_type=6,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_radio(
        self, radio_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Radio comments (thread ``R_RD_7_<id>``)."""
        return self.comment_resource(
            self.thread_id("radio", radio_id),
            resource_id=radio_id,
            resource_type=7,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_video(
        self, video_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Video comments (thread ``R_VI_8_<id>``)."""
        return self.comment_resource(
            self.thread_id("video", video_id),
            resource_id=video_id,
            resource_type=8,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_mlog(
        self, mlog_id: str | int, limit: int = 20, offset: int = 0, **extra: Any
    ) -> dict[str, Any]:
        """Mlog comments (thread ``R_MLOG_13_<id>``)."""
        return self.comment_resource(
            self.thread_id("mlog", mlog_id),
            resource_id=mlog_id,
            resource_type=13,
            limit=limit,
            offset=offset,
            **extra,
        )

    def comment_floor(
        self,
        thread_id: str,
        parent_comment_id: str | int,
        limit: int = 20,
        time: int = 0,
        cursor: int | None = None,
        order: str = "new",
        **extra: Any,
    ) -> dict[str, Any]:
        """Replies to a comment.  Route: ``v2/resource/comment/floor/get``."""
        params = self._resource_params(thread_id, None, None)
        params.update(
            self._clean(
                parentCommentId=parent_comment_id,
                limit=limit,
                time=time,
                cursor=cursor,
                order=order,
                **extra,
            )
        )
        return self.call("v2/resource/comment/floor/get", **params)

    def comment_hot(
        self,
        thread_id: str,
        resource_id: str | int | None = None,
        resource_type: str | int | None = None,
        limit: int = 20,
        before_time: int = 0,
        **extra: Any,
    ) -> dict[str, Any]:
        """Recent hot comments.  Route: ``comment/recenthotcomment/get``."""
        params = self._resource_params(thread_id, resource_id, resource_type)
        params.update(
            self._clean(limit=limit, beforeTime=before_time, hot=True, **extra)
        )
        return self.call("comment/recenthotcomment/get", **params)

    def comment_info(self, thread_id: str, **extra: Any) -> dict[str, Any]:
        """Comment resource info.  Route: ``resource/commentInfo/list``."""
        return self.call("resource/commentInfo/list", threadId=thread_id, **extra)

    # -------------------------------------------------------------- writing
    def comment_add(
        self,
        thread_id: str,
        content: str,
        resource_id: str | int | None = None,
        resource_type: str | int | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Post a comment.  Route: ``v1/resource/comments/add``."""
        params = self._resource_params(thread_id, resource_id, resource_type)
        params["content"] = content
        params.update(extra)
        return self.call("v1/resource/comments/add", **params)

    def comment_reply(
        self,
        thread_id: str,
        comment_id: str | int,
        content: str,
        resource_id: str | int | None = None,
        resource_type: str | int | None = None,
        **extra: Any,
    ) -> dict[str, Any]:
        """Reply to a comment.  Route: ``v1/resource/comments/reply``."""
        params = self._resource_params(thread_id, resource_id, resource_type)
        params.update(commentId=comment_id, content=content)
        params.update(extra)
        return self.call("v1/resource/comments/reply", **params)

    def comment_delete(
        self,
        thread_id: str,
        comment_id: str | int,
        resource_id: str | int | None = None,
        resource_type: str | int | None = None,
    ) -> dict[str, Any]:
        """Delete a comment.  Route: ``resource/comments/delete``."""
        params = self._resource_params(thread_id, resource_id, resource_type)
        params["commentId"] = comment_id
        return self.call("resource/comments/delete", **params)

    def comment_like(self, thread_id: str, comment_id: str | int) -> dict[str, Any]:
        """Like a comment.  Route: ``v1/comment/like``."""
        return self.call("v1/comment/like", threadId=thread_id, commentId=comment_id)

    def comment_unlike(self, thread_id: str, comment_id: str | int) -> dict[str, Any]:
        """Unlike a comment.  Route: ``v1/comment/unlike``."""
        return self.call("v1/comment/unlike", threadId=thread_id, commentId=comment_id)

    def comment_operate(
        self, thread_id: str, comment_id: str | int, opt_type: int
    ) -> dict[str, Any]:
        """Comment operation (delete/report/etc.).  Route: ``comment/user/operate``."""
        return self.call(
            "comment/user/operate",
            threadId=thread_id,
            commentId=comment_id,
            optType=opt_type,
        )
