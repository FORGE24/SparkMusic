"""Broad smoke tests for the mixin methods (no network)."""
from __future__ import annotations

import hashlib
import unittest

from netease_api import NeteaseClient
from netease_api.apis import MIXINS

from .test_client import RecordingTransport


class ApiSmokeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.transport = RecordingTransport()
        self.client = NeteaseClient(transport=self.transport)

    def last(self) -> dict:
        return self.transport.calls[-1]

    # ------------------------------------------------------------------ login
    def test_login_cellphone_hashes_password(self) -> None:
        self.client.login_cellphone("13800000000", "secret")
        call = self.last()
        self.assertEqual(call["route"], "login/cellphone")
        self.assertEqual(call["params"]["password"], hashlib.md5(b"secret").hexdigest())
        self.assertEqual(call["params"]["phone"], "13800000000")
        self.assertEqual(call["params"]["countrycode"], "86")
        self.assertEqual(call["mode"], "weapi")

    def test_login_cellphone_captcha(self) -> None:
        self.client.login_cellphone("13800000000", captcha="1234")
        self.assertEqual(self.last()["params"]["captcha"], "1234")
        self.assertNotIn("password", self.last()["params"])

    def test_login_email(self) -> None:
        self.client.login_email("a@b.c", "pw")
        self.assertEqual(self.last()["route"], "login")
        self.assertEqual(self.last()["mode"], "weapi")

    def test_captcha_and_register(self) -> None:
        self.client.captcha_send("13800000000")
        self.assertEqual(self.last()["route"], "sms/captcha/sent")
        self.client.captcha_verify("13800000000", "1234")
        self.assertEqual(self.last()["route"], "sms/captcha/verify")
        self.client.register_cellphone("13800000000", "pw", "1234", "nick")
        self.assertEqual(self.last()["route"], "register/cellphone")

    # ------------------------------------------------------------------- user
    def test_user_routes(self) -> None:
        cases = [
            (lambda: self.client.user_detail(1), "v1/user/detail/1"),
            (lambda: self.client.user_info(), "v1/user/info"),
            (lambda: self.client.user_playlists(1), "user/playlist"),
            (lambda: self.client.user_follows(1), "user/getfollows/1"),
            (lambda: self.client.user_follow(1), "user/follow/1"),
            (lambda: self.client.user_unfollow(1), "user/delfollow/1"),
            (lambda: self.client.user_bothfollow(1), "user/bothfollow"),
            (lambda: self.client.user_comments(1), "v1/user/comments/1"),
            (lambda: self.client.user_playlist_collect(5), "user/playlist/collect"),
        ]
        for call, route in cases:
            call()
            self.assertEqual(self.last()["route"], route)

    def test_user_playlists_params(self) -> None:
        self.client.user_playlists(1, limit=50, offset=10, include_video=True)
        params = self.last()["params"]
        self.assertEqual((params["uid"], params["limit"], params["offset"]), (1, 50, 10))
        self.assertEqual(params["includeVideo"], "true")

    def test_play_record_kinds(self) -> None:
        for kind in ("song", "album", "playlist", "djradio", "newvideo"):
            self.client.play_record(1, kind=kind)
            self.assertEqual(self.last()["route"], f"play-record/{kind}/list")

    # ------------------------------------------------------------------ music
    def test_song_routes(self) -> None:
        self.client.song_lyric(1)
        self.assertEqual(self.last()["route"], "song/lyric/v1")
        self.client.song_like(1, True)
        self.assertEqual(self.last()["route"], "song/like")
        self.assertEqual(self.last()["params"]["like"], "true")
        self.client.song_like_get()
        self.assertEqual(self.last()["route"], "song/like/get")
        self.client.song_privilege([1, 2])
        self.assertEqual(self.last()["route"], "song/enhance/privilege")

    def test_album_routes(self) -> None:
        self.client.album_detail(1)
        self.assertEqual(self.last()["route"], "album/1")
        self.assertEqual(self.last()["params"], {})
        self.client.album_subscribe(1, True)
        self.assertEqual(self.last()["route"], "album/sub")
        self.client.album_subscribe(1, False)
        self.assertEqual(self.last()["route"], "album/unsub")

    def test_artist_routes(self) -> None:
        self.client.artist_songs(1)
        self.assertEqual(self.last()["route"], "v2/artist/songs")
        self.client.artist_albums(1)
        self.assertEqual(self.last()["route"], "artist/albums/1")
        self.client.artist_subscribe(1)
        self.assertEqual(self.last()["route"], "v1/artist/sub")

    def test_mv_routes(self) -> None:
        self.client.mv_detail(1)
        self.assertEqual(self.last()["route"], "v1/mv/detail")
        self.client.mv_url(1)
        self.assertEqual(self.last()["route"], "song/enhance/download/mv/url")

    # --------------------------------------------------------------- playlist
    def test_playlist_create_privacy_integer(self) -> None:
        # The service rejects JSON booleans with 400 参数错误, so booleans must
        # be normalised before the payload is built.
        self.client.playlist_create("name", privacy=False)
        self.assertEqual(self.last()["params"]["privacy"], 0)
        self.client.playlist_create("name", privacy=True)
        self.assertEqual(self.last()["params"]["privacy"], 10)
        self.client.playlist_create("name", privacy=0)
        self.assertEqual(self.last()["params"]["privacy"], 0)

    def test_playlist_remove_and_order_self_parameter(self) -> None:
        # ``self`` is a protocol parameter and must survive the client's own
        # ``self`` argument.
        self.client.playlist_delete([1, 2])
        self.assertEqual(self.last()["route"], "playlist/remove")
        self.assertEqual(self.last()["params"]["self"], "true")
        self.client.playlist_order_update([3])
        self.assertEqual(self.last()["route"], "playlist/order/update")
        self.assertEqual(self.last()["params"]["ids"], "3")

    def test_playlist_edit_routes(self) -> None:
        self.client.playlist_create("name", privacy=0)
        self.assertEqual(self.last()["route"], "playlist/create")
        self.client.playlist_add_tracks(1, [2, 3])
        self.assertEqual(self.last()["route"], "playlist/manipulate/tracks")
        self.assertEqual(self.last()["params"]["op"], "add")
        self.assertEqual(self.last()["params"]["trackIds"], "[2,3]")
        self.client.playlist_del_tracks(1, [2])
        self.assertEqual(self.last()["params"]["op"], "del")
        self.client.playlist_subscribe(1, False)
        self.assertEqual(self.last()["params"]["t"], 0)
        self.client.playlist_update_name(1, "new")
        self.assertEqual(self.last()["route"], "playlist/update/name")
        self.assertEqual(self.last()["params"]["name"], "new")
        self.client.playlist_update_desc(1, "text")
        self.assertEqual(self.last()["route"], "playlist/desc/update")
        self.assertEqual(self.last()["params"]["desc"], "text")
        self.client.playlist_update_tags(1, ["rock", "pop"])
        self.assertEqual(self.last()["params"]["tags"], "rock;pop")
        self.client.playlist_update_privacy(1, True)
        self.assertEqual(self.last()["params"]["privacy"], 10)
        self.client.playlist_update_privacy(1, False)
        self.assertEqual(self.last()["params"]["privacy"], 0)

    # ----------------------------------------------------------------- search
    def test_search_routes(self) -> None:
        self.client.search_songs("x", limit=5)
        self.assertEqual(self.last()["route"], "v1/search/get")
        self.assertEqual(self.last()["params"]["type"], 1)
        self.assertEqual(self.last()["params"]["s"], "x")
        self.client.search_playlists("x")
        self.assertEqual(self.last()["params"]["type"], 1000)
        self.client.search_complex("x")
        self.assertEqual(self.last()["route"], "search/complex/page")
        self.client.search_suggest("x")
        self.assertEqual(self.last()["route"], "search/suggest/keyword")

    # ---------------------------------------------------------------- comment
    def test_comment_routes(self) -> None:
        self.client.comment_floor("R_SO_4_1", 2)
        self.assertEqual(self.last()["route"], "v2/resource/comment/floor/get")
        self.assertEqual(self.last()["params"]["parentCommentId"], 2)
        self.client.comment_add("R_SO_4_1", "hi")
        self.assertEqual(self.last()["route"], "v1/resource/comments/add")
        self.client.comment_like("R_SO_4_1", 2)
        self.assertEqual(self.last()["route"], "v1/comment/like")
        self.client.comment_delete("R_SO_4_1", 2)
        self.assertEqual(self.last()["route"], "resource/comments/delete")

    # --------------------------------------------------------------- dj/radio
    def test_dj_routes(self) -> None:
        self.client.dj_program_detail(1)
        self.assertEqual(self.last()["route"], "dj/program/detail")
        self.client.dj_program_byradio(1)
        self.assertEqual(self.last()["route"], "v1/dj/program/byradio")
        self.client.dj_radio_subscribe(1, False)
        self.assertEqual(self.last()["route"], "djradio/unsub")

    def test_radio_routes(self) -> None:
        self.client.radio_get()
        self.assertEqual(self.last()["route"], "v1/radio/get")
        self.client.radio_like(1, True)
        self.assertEqual(self.last()["route"], "v1/radio/like")
        self.client.radio_skip(1)
        self.assertEqual(self.last()["route"], "v1/radio/skip")

    # -------------------------------------------------------------- recommend
    def test_recommend_routes(self) -> None:
        self.client.recommend_songs()
        self.assertEqual(self.last()["route"], "v3/discovery/recommend/songs")
        self.client.simi_song(1)
        self.assertEqual(self.last()["route"], "v1/discovery/simiSong")
        self.client.toplist_artist()
        self.assertEqual(self.last()["route"], "toplist/artist")

    # ----------------------------------------------------------------- social
    def test_social_routes(self) -> None:
        self.client.user_events(1)
        self.assertEqual(self.last()["route"], "event/get/1")
        self.client.event_detail(1)
        self.assertEqual(self.last()["route"], "event/detail/get/v1")
        self.client.mlog_detail(1)
        self.assertEqual(self.last()["route"], "mlog/detail")
        self.client.mlog_songmlog(1, order="score")
        self.assertEqual(self.last()["route"], "mlog/songmlog/bysocre/get/v2")
        self.client.topic_sub(1)
        self.assertEqual(self.last()["route"], "topic/sub")
        self.client.msg_private_send([1, 2], "hi")
        self.assertEqual(self.last()["params"]["userIds"], "1,2")

    # ------------------------------------------------------------ cloud/vip
    def test_cloud_routes(self) -> None:
        self.client.cloud_songs(limit=10)
        self.assertEqual(self.last()["route"], "v3/cloud/get")
        self.client.cloud_upload_check("a.mp3", 10, "abc")
        self.assertEqual(self.last()["route"], "cloud/file/upload/check")
        self.client.cloud_delete([1, 2])
        self.assertEqual(self.last()["params"]["songIds"], "1,2")
        self.client.vip_info()
        self.assertEqual(self.last()["route"], "music-vip-membership/client/vip/info")

    # ------------------------------------------------------------------- misc
    def test_misc_routes(self) -> None:
        self.client.report_user(1, "spam")
        self.assertEqual(self.last()["route"], "report/reportuser")
        self.client.report_comment("R_SO_4_1", 2, "spam")
        self.assertEqual(self.last()["route"], "report/reportcomment")
        self.client.feedback_lyric(1, 2)
        self.assertEqual(self.last()["route"], "v1/feedback/lyric")
        self.client.together_status()
        self.assertEqual(self.last()["route"], "listen/together/status/get")
        self.client.mine_tab_counts()
        self.assertEqual(self.last()["route"], "mine/page/tab/nums/count")

    # ---------------------------------------------------------------- structure
    def test_no_duplicate_method_names_across_mixins(self) -> None:
        seen: dict[str, str] = {}
        for mixin in MIXINS:
            for name, value in vars(mixin).items():
                if name.startswith("_") or not callable(value):
                    continue
                if name in ("call", "endpoint", "thread_id"):
                    continue
                self.assertNotIn(
                    name, seen, f"{name} defined in both {seen.get(name)} and {mixin.__name__}"
                )
                seen[name] = mixin.__name__
        self.assertGreater(len(seen), 250)

    def test_every_client_method_is_callable(self) -> None:
        checked = 0
        for name in dir(self.client):
            if name.startswith("_"):
                continue
            value = getattr(self.client, name)
            if callable(value):
                checked += 1
        self.assertGreater(checked, 300)


if __name__ == "__main__":
    unittest.main()
