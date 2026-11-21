"""DJ radio, DJ program and personal FM endpoints."""
from __future__ import annotations

from typing import Any, Iterable

from .base import ApiMixin

__all__ = ["DjApi", "RadioApi"]


class DjApi(ApiMixin):
    """DJ program/radio endpoints recovered from 9.6.30."""

    def dj_program_detail(self, program_id: str | int) -> dict[str, Any]:
        """Program detail.  Route: ``dj/program/detail``."""
        return self.call("dj/program/detail", id=program_id)

    def dj_program_batch_detail(
        self, program_ids: Iterable[str | int] | str
    ) -> dict[str, Any]:
        """Batch program detail.  Route: ``dj/program/batch/detail``."""
        return self.call("dj/program/batch/detail", ids=self._ids(program_ids))

    def dj_program_byradio(
        self,
        radio_id: str | int,
        limit: int = 30,
        offset: int = 0,
        asc: bool = False,
        **extra: Any,
    ) -> dict[str, Any]:
        """Programs of a radio.  Route: ``v1/dj/program/byradio``."""
        return self.call(
            "v1/dj/program/byradio",
            radioId=radio_id,
            limit=limit,
            offset=offset,
            asc=self._flag(asc),
            **extra,
        )

    def dj_program_search(self, keyword: str, limit: int = 30, offset: int = 0) -> dict[str, Any]:
        """Search programs.  Route: ``dj/radio/program/search``."""
        return self.call(
            "dj/radio/program/search", keyword=keyword, limit=limit, offset=offset
        )

    def dj_program_playrecord(self, limit: int = 30, offset: int = 0) -> dict[str, Any]:
        """Recently played programs.  Route: ``dj/playrecord/program/get``."""
        return self.call("dj/playrecord/program/get", limit=limit, offset=offset)

    def dj_program_xiayi(self, program_id: str | int) -> dict[str, Any]:
        """Program 'xiayi' detail.  Route: ``dj/program/xiayi/detail``."""
        return self.call("dj/program/xiayi/detail", id=program_id)

    def dj_radio_detail(self, radio_id: str | int) -> dict[str, Any]:
        """Radio detail.  Route: ``djradio/get``."""
        return self.call("djradio/get", id=radio_id)

    def dj_radio_detail_v3(self, radio_id: str | int) -> dict[str, Any]:
        """Radio detail (v3).  Route: ``djradio/v3/get``."""
        return self.call("djradio/v3/get", id=radio_id)

    def dj_radio_byuser(
        self, user_id: str | int, limit: int = 30, offset: int = 0
    ) -> dict[str, Any]:
        """Radios owned by a user.  Route: ``djradio/get/byuser/v1``."""
        return self.call(
            "djradio/get/byuser/v1", userId=user_id, limit=limit, offset=offset
        )

    def dj_radio_subscribe(self, radio_id: str | int, subscribe: bool = True) -> dict[str, Any]:
        """Subscribe/unsubscribe.  Routes: ``djradio/sub`` / ``djradio/unsub``."""
        return self.call(
            "djradio/sub" if subscribe else "djradio/unsub", id=radio_id
        )

    def dj_radio_buy(
        self,
        radio_id: str | int,
        pay_type: int = 0,
        pay_method: str = "alipay",
        **extra: Any,
    ) -> dict[str, Any]:
        """Buy a radio.  Route: ``djradio/buyradio``."""
        return self.call(
            "djradio/buyradio",
            radioId=radio_id,
            payType=pay_type,
            payMethod=pay_method,
            **extra,
        )

    def dj_program_buy(
        self,
        radio_id: str | int,
        program_ids: Iterable[str | int] | str,
        pay_type: int = 0,
        pay_method: str = "alipay",
        **extra: Any,
    ) -> dict[str, Any]:
        """Buy programs.  Route: ``djradio/buyprogram``."""
        return self.call(
            "djradio/buyprogram",
            radioId=radio_id,
            programIds=self._ids(program_ids),
            payType=pay_type,
            payMethod=pay_method,
            **extra,
        )

    def dj_radio_carfm(self, radio1: str | int, **extra: Any) -> dict[str, Any]:
        """Car FM.  Route: ``djradio/carfm/get``."""
        return self.call("djradio/carfm/get", radio1=radio1, **extra)

    def dj_my_radio_recommend(self) -> dict[str, Any]:
        """Recommended radios.  Route: ``djradio/my/radio/recommend``."""
        return self.call("djradio/my/radio/recommend")

    def dj_playrecord_radio(self, limit: int = 100, offset: int = 0) -> dict[str, Any]:
        """Recently played radios.  Route: ``dj/playrecord/radio/get``."""
        return self.call("dj/playrecord/radio/get", limit=limit, offset=offset)

    def dj_program_danmaku_list(
        self, program_id: str | int, **extra: Any
    ) -> dict[str, Any]:
        """Program danmaku.  Route: ``dj/program/danmaku/wild/list``."""
        return self.call("dj/program/danmaku/wild/list", programId=program_id, **extra)

    def dj_program_like(
        self,
        program_id: str | int,
        like: bool = True,
        time: int = 0,
        alg: str = "",
        **extra: Any,
    ) -> dict[str, Any]:
        """Like a program.  Route: ``v1/radio/like``.

        The app tracks radio interactions with ``time``/``alg``/``mode``; they
        are forwarded when supplied.
        """
        return self.call(
            "v1/radio/like",
            trackId=program_id,
            like=self._flag(like),
            time=time,
            alg=alg,
            **extra,
        )


class RadioApi(ApiMixin):
    """Personal FM / 'radio' endpoints recovered from 9.6.30."""

    def radio_get(self, **extra: Any) -> dict[str, Any]:
        """Personal FM queue.  Route: ``v1/radio/get``."""
        return self.call("v1/radio/get", **extra)

    def radio_like(
        self,
        track_id: str | int,
        like: bool = True,
        time: int = 0,
        alg: str = "",
        source: str = "",
        **extra: Any,
    ) -> dict[str, Any]:
        """Like the current FM track.  Route: ``v1/radio/like``."""
        return self.call(
            "v1/radio/like",
            trackId=track_id,
            like=self._flag(like),
            time=time,
            alg=alg,
            source=source,
            **extra,
        )

    def radio_skip(self, song_id: str | int, time: int = 0, alg: str = "", **extra: Any):
        """Skip the current FM track.  Route: ``v1/radio/skip``."""
        return self.call("v1/radio/skip", songId=song_id, time=time, alg=alg, **extra)

    def radio_trash(self, song_id: str | int, time: int = 0, alg: str = "", **extra: Any):
        """Dislike the current FM track.  Route: ``v1/radio/trash/add``."""
        return self.call(
            "v1/radio/trash/add", songId=song_id, time=time, alg=alg, **extra
        )

    def radio_sport_get(self, bpm: int = 120) -> dict[str, Any]:
        """Sport FM queue.  Route: ``radio/sport/get``."""
        return self.call("radio/sport/get", bpm=bpm)

    def radio_sport_calculate(self, **extra: Any) -> dict[str, Any]:
        """Recalculate sport FM.  Route: ``radio/sport/calculate``."""
        return self.call("radio/sport/calculate", **extra)

    def radio_sport_like(
        self,
        song_id: str | int,
        like: bool = True,
        alg: str = "",
        time: int = 0,
        sport_bpm: int | None = None,
        radio_bpm: int | None = None,
    ) -> dict[str, Any]:
        """Like a sport-FM track.  Route: ``radio/sport/like``."""
        return self.call(
            "radio/sport/like",
            songId=song_id,
            like=self._flag(like),
            alg=alg,
            time=time,
            sbpm=sport_bpm,
            rbpm=radio_bpm,
        )

    def radio_sport_skip(
        self,
        song_id: str | int,
        alg: str = "",
        time: int = 0,
        sport_bpm: int | None = None,
        radio_bpm: int | None = None,
    ) -> dict[str, Any]:
        """Skip a sport-FM track.  Route: ``radio/sport/skip``."""
        return self.call(
            "radio/sport/skip",
            songId=song_id,
            alg=alg,
            time=time,
            sbpm=sport_bpm,
            rbpm=radio_bpm,
        )

    def radio_sport_trash(
        self,
        song_id: str | int,
        alg: str = "",
        time: int = 0,
        sport_bpm: int | None = None,
        radio_bpm: int | None = None,
    ) -> dict[str, Any]:
        """Dislike a sport-FM track.  Route: ``radio/sport/trash/add``."""
        return self.call(
            "radio/sport/trash/add",
            songId=song_id,
            alg=alg,
            time=time,
            sbpm=sport_bpm,
            rbpm=radio_bpm,
        )

    def radio_sport_offline(
        self, max_tracks: int = 30, song: str = ""
    ) -> dict[str, Any]:
        """Offline sport-FM batch.  Route: ``radio/sport/offline/song/get``."""
        return self.call("radio/sport/offline/song/get", max=max_tracks, song=song)
