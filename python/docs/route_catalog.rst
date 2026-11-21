Route catalog
=============

1293 canonical routes in 150 groups. 1045 are tied to a request-builder method recovered from the 9.6.30 DEX code; 248 were inferred from route-shaped string constants that the app assembles dynamically.

``params`` lists the body/query keys recovered from the app's ``put`` calls or query templates. A route marked **inferred** has no recovered parameter list unless one is shown.

.. list-table:: Routes per group
   :header-rows: 1
   :widths: 40 10

   * - Group
     - Routes
   * - livestream
     - 114
   * - user
     - 88
   * - listen
     - 68
   * - mlog
     - 65
   * - playlist
     - 60
   * - event
     - 52
   * - music
     - 44
   * - dj
     - 39
   * - song
     - 38
   * - search
     - 34
   * - ad
     - 32
   * - homepage
     - 31
   * - resource
     - 30
   * - comment
     - 28
   * - mlivestream
     - 26
   * - voice
     - 24
   * - artist
     - 23
   * - usertool
     - 22
   * - cloud
     - 20
   * - djradio
     - 20
   * - discovery
     - 15
   * - login
     - 15
   * - follow
     - 14
   * - clientlog
     - 12
   * - icreator
     - 12
   * - sociallive
     - 12
   * - album
     - 11
   * - topic
     - 11
   * - vipauth
     - 11
   * - content
     - 10
   * - middle
     - 10
   * - radio
     - 10
   * - activity
     - 9
   * - reward
     - 9
   * - act
     - 8
   * - report
     - 8
   * - msg
     - 7
   * - nuser
     - 7
   * - social
     - 7
   * - circle
     - 6
   * - cloudvideo
     - 6
   * - mine
     - 6
   * - socialsquare
     - 6
   * - sp
     - 6
   * - djprogram
     - 5
   * - mv
     - 5
   * - personalized
     - 5
   * - play-record
     - 5
   * - setting
     - 5
   * - story
     - 5
   * - sub
     - 5
   * - vip
     - 5
   * - baby
     - 4
   * - largeshow
     - 4
   * - quality
     - 4
   * - alarm
     - 3
   * - college
     - 3
   * - delivery
     - 3
   * - feedback
     - 3
   * - lyricvideo
     - 3
   * - mix
     - 3
   * - nearby
     - 3
   * - pendant
     - 3
   * - podcast
     - 3
   * - resniche
     - 3
   * - resource-exposure
     - 3
   * - socialmix
     - 3
   * - symphony
     - 3
   * - toplist
     - 3
   * - videotimeline
     - 3
   * - vipmall
     - 3
   * - vipnewcenter
     - 3
   * - w
     - 3
   * - aio
     - 2
   * - android
     - 2
   * - concert
     - 2
   * - fans
     - 2
   * - light
     - 2
   * - link
     - 2
   * - live
     - 2
   * - log
     - 2
   * - lunacache
     - 2
   * - magent
     - 2
   * - matcher
     - 2
   * - music-vip-open
     - 2
   * - music-vip-thoth
     - 2
   * - newuser
     - 2
   * - nickname
     - 2
   * - popularmusic
     - 2
   * - register
     - 2
   * - rncache
     - 2
   * - share
     - 2
   * - sms
     - 2
   * - theme
     - 2
   * - upload
     - 2
   * - vip-rights
     - 2
   * - yunbei
     - 2
   * - %s
     - 1
   * - about
     - 1
   * - activate
     - 1
   * - activitycenter
     - 1
   * - appcustomconfig
     - 1
   * - auth
     - 1
   * - autopay
     - 1
   * - banner
     - 1
   * - batch
     - 1
   * - block
     - 1
   * - cart
     - 1
   * - cdns
     - 1
   * - cellphone
     - 1
   * - communication
     - 1
   * - community
     - 1
   * - coop
     - 1
   * - creator
     - 1
   * - deviceinfo
     - 1
   * - douyin
     - 1
   * - file
     - 1
   * - flow
     - 1
   * - getconfig
     - 1
   * - ichat
     - 1
   * - lt
     - 1
   * - mgrhome
     - 1
   * - music-vip-membership
     - 1
   * - music-vip-rights
     - 1
   * - my
     - 1
   * - order
     - 1
   * - page
     - 1
   * - password
     - 1
   * - personal
     - 1
   * - pl
     - 1
   * - play
     - 1
   * - playmode
     - 1
   * - point
     - 1
   * - privacy
     - 1
   * - privilege
     - 1
   * - purchased
     - 1
   * - sdk
     - 1
   * - side-bar
     - 1
   * - similar
     - 1
   * - spider
     - 1
   * - springtone
     - 1
   * - stoplivechallenge
     - 1
   * - subcount
     - 1
   * - throughtrain
     - 1
   * - usersafe
     - 1
   * - vip-auth
     - 1
   * - vipmusic
     - 1
   * - voicelist
     - 1
   * - webcache
     - 1
   * - zone
     - 1

livestream (114)
----------------

* ``livestream/act/tunnel/random/living/recommend`` *(inferred)*
* ``livestream/activity/city/peach/blossom/open/check`` *(inferred)*
* ``livestream/activity/city/peach/blossom/task/query`` *(inferred)*
* ``livestream/anchor/follow`` *(inferred)*
* ``livestream/anchor/gift/wall/complex/tips`` *(inferred)*
* ``livestream/anchor/monster/phase/info/get`` *(inferred)*
* ``livestream/brand/material/enterroom/get`` *(inferred)*
* ``livestream/brand/material/enterroom/resource/get`` *(inferred)*
* ``livestream/brand/material/image/get`` *(inferred)*
* ``livestream/continuous/variety/program/topic/button/info`` *(inferred)*
* ``livestream/continuous/variety/program/topic/open`` *(inferred)*
* ``livestream/downloadgift/user/handle/task`` *(inferred)*
* ``livestream/extension/astrolabe/exist/get`` *(inferred)*
* ``livestream/fanclub/list/pop/v2`` *(inferred)*
* ``livestream/fans/del`` *(inferred)*
* ``livestream/follow/lastend`` *(inferred)*
* ``livestream/gift/group/resource/get`` *(inferred)*
* ``livestream/gift/magic/resource/list`` *(inferred)*
* ``livestream/gift/panel/banner/config/list`` *(inferred)*
* ``livestream/gift/panel/guide/get`` *(inferred)*
* ``livestream/guild/firstConsume/check`` *(inferred)*
* ``livestream/heartbeat/archor``
* ``livestream/homepage/anonymous/v1`` *(inferred)*
* ``livestream/homepage/music/recommend/roll-polling/v1`` *(inferred)*
* ``livestream/homepage/voice/v1`` *(inferred)*
* ``livestream/hotline/consult/config/get`` *(inferred)*
* ``livestream/hotline/consult/config/switch/update`` *(inferred)*
* ``livestream/hotline/consult/config/update`` *(inferred)*
* ``livestream/hotline/consult/info`` *(inferred)*
* ``livestream/hotline/consult/rate`` *(inferred)*
* ``livestream/hotline/consult/user/askLive`` *(inferred)*
* ``livestream/hotline/consult/user/renew`` *(inferred)*
* ``livestream/intimacy/dualavatar/switch`` *(inferred)*
* ``livestream/intimacy/dualavatar/top`` *(inferred)*
* ``livestream/intimacy/fanclub/greyed/list`` *(inferred)*
* ``livestream/intimacy/fanclub/list`` *(inferred)*
* ``livestream/intimacy/relationship/detail/user`` *(inferred)*
* ``livestream/intimacy/relationship/get`` *(inferred)*
* ``livestream/intimacy/relationship/greyed/list`` *(inferred)*
* ``livestream/intimacy/relationship/list`` *(inferred)*
* ``livestream/intimacy/resource/list`` *(inferred)*
* ``livestream/intimacy/token/check`` *(inferred)*
* ``livestream/iplay/fun/roominteraction/viewer`` *(inferred)*
* ``livestream/look/homepage/recommend/v1`` *(inferred)*
* ``livestream/magic/headline/history/query`` *(inferred)*
* ``livestream/msg/count/clear`` *(inferred)*
* ``livestream/msg/private/risk/check`` *(inferred)*
* ``livestream/music/personal/notices`` *(inferred)*
* ``livestream/numen/base/info`` *(inferred)*
* ``livestream/party/room/play/dynamic`` *(inferred)*
* ``livestream/party/wish/gift/progress/query`` *(inferred)*
* ``livestream/personalpage/anchor/work/info`` *(inferred)*
* ``livestream/personalpage/info/v2`` *(inferred)*
* ``livestream/personalpage/url`` *(inferred)*
* ``livestream/pipe/dragonball/recommend/room/live/check`` *(inferred)*
* ``livestream/pipe/dragonball/recommend/room/live/get`` *(inferred)*
* ``livestream/pipe/pk/status/get`` *(inferred)*
* ``livestream/pk/divination/astrolabe/invite`` *(inferred)*
* ``livestream/pk/divination/astrolabe/invite/accept`` *(inferred)*
* ``livestream/pk/divination/astrolabe/invite/reject`` *(inferred)*
* ``livestream/pk/divination/tarot/invite`` *(inferred)*
* ``livestream/pk/divination/tarot/invite/accept`` *(inferred)*
* ``livestream/pk/divination/tarot/invite/reject`` *(inferred)*
* ``livestream/pk/paychat/free/rtc/call`` *(inferred)*
* ``livestream/pk/paychat/music/recommend`` *(inferred)*
* ``livestream/pk/paychat/order/card/info/get`` *(inferred)*
* ``livestream/public/room/emoji/send`` *(inferred)*
* ``livestream/push/click/event/report`` *(inferred)*
* ``livestream/rand/gift/filter`` *(inferred)*
* ``livestream/relation/flame/get`` *(inferred)*
* ``livestream/relation/flame/passive/nolight`` *(inferred)*
* ``livestream/reward/rewardbox/core/detail/batch`` *(inferred)*
* ``livestream/room/close/reason/get`` *(inferred)*
* ``livestream/room/emoji/resources/list/v3`` *(inferred)*
* ``livestream/room/emoji/send/v2`` *(inferred)*
* ``livestream/room/end/info/get`` *(inferred)*
* ``livestream/room/enter/material/get`` *(inferred)*
* ``livestream/room/get/v3``
* ``livestream/room/privilege/precheck`` *(inferred)*
* ``livestream/room/recent/get`` *(inferred)*
* ``livestream/rtc/common/type`` *(inferred)*
* ``livestream/rtc/fan/club/gift/list`` *(inferred)*
* ``livestream/rtc/multi/auction/relation/query`` *(inferred)*
* ``livestream/rtc/multi/cover/status/query`` *(inferred)*
* ``livestream/rtc/multi/cross/pk/accept`` *(inferred)*
* ``livestream/rtc/multi/cross/pk/latest/get`` *(inferred)*
* ``livestream/rtc/multi/cross/pk/reject`` *(inferred)*
* ``livestream/rtc/multi/melee/end`` *(inferred)*
* ``livestream/rtc/multi/melee/result/end`` *(inferred)*
* ``livestream/rtc/multi/melee/start`` *(inferred)*
* ``livestream/rtc/pk/gift/list`` *(inferred)*
* ``livestream/share/info`` *(inferred)*
* ``livestream/skin/background/get`` *(inferred)*
* ``livestream/spirit/pet/user/get`` *(inferred)*
* ``livestream/subscribe/add`` *(inferred)*
* ``livestream/subscribe/cancel`` *(inferred)*
* ``livestream/user/current/room`` *(inferred)*
* ``livestream/user/gift/discount/active`` *(inferred)*
* ``livestream/user/homework/check`` *(inferred)*
* ``livestream/user/homework/popup/query`` *(inferred)*
* ``livestream/user/mypage/edit/permission/check`` *(inferred)*
* ``livestream/user/notice/count/clear`` *(inferred)*
* ``livestream/user/notice/count/get`` *(inferred)*
* ``livestream/user/protect/state/report`` *(inferred)*
* ``livestream/user/recall/popup/query`` *(inferred)*
* ``livestream/userinfo/citylive/artists/get`` *(inferred)*
* ``livestream/userprivilege/common/config/list`` *(inferred)*
* ``livestream/userprivilege/common/config/list/delta`` *(inferred)*
* ``livestream/usertag/all/list`` *(inferred)*
* ``livestream/usertag/tag/batch/get`` *(inferred)*
* ``livestream/video/multi/change`` *(inferred)*
* ``livestream/video/multi/end`` *(inferred)*
* ``livestream/yunbeitask/finish`` *(inferred)*
* ``livestream/yunbeitask/live/recommend`` *(inferred)*

user (88)
---------

* ``user/async/batchfollow``
* ``user/avatar/upload/v1``
* ``user/background/get``
* ``user/background/upload/v1``
* ``user/batchfollow``
* ``user/bindingcellphone/v1``
* ``user/bindings/%d`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``user/bindingsns`` — ``type``, ``tokenJsonStr``, ``screen_name``, ``nickname``
* ``user/bothfollow`` — ``uid``
* ``user/cloud/configure/get``
* ``user/cloud/remove/count``
* ``user/comments/reply`` — ``combindId``, ``expressionPicId``, ``checkToken``, ``anonym``
* ``user/commoninterests/count`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``user/content/setting`` — ``bizCode``
* ``user/current/profile``
* ``user/custom/eq/trail/strategy/get``
* ``user/default/background`` — ``minepage_v4``
* ``user/delfollow/%d``
* ``user/follow/%d``
* ``user/follow/dislike``
* ``user/follow/users/get`` — ``lasttime``, ``limit``, ``order``
* ``user/follow/users/mixed/get/v2``
* ``user/followed/new/clear``
* ``user/followed/remove``
* ``user/friend/new/song/notice/get`` — ``adextjson``, ``extPageParam``, ``lasttime``, ``pagesize``, ``rcmdtopic``, ``rcmduser``, ``netstate``, ``resolution``, ``needUrl``, ``pagenum``, ``type``, ``eventId``, ``eventUserId``, ``curr_impressed_ids``, ``algLogInfo``, ``redEventId``, ``adExtJson``, ``pageNumber``, ``pageSize``, ``scene``, ``time``
* ``user/friend/through/train/message``
* ``user/friend/through/train/v1/get`` — ``adextjson``, ``extPageParam``, ``lasttime``, ``pagesize``, ``rcmdtopic``, ``rcmduser``, ``netstate``, ``resolution``, ``needUrl``, ``pagenum``, ``type``, ``eventId``, ``eventUserId``, ``curr_impressed_ids``, ``algLogInfo``, ``redEventId``, ``adExtJson``, ``pageNumber``, ``pageSize``, ``scene``, ``time``
* ``user/get/star/podcast``
* ``user/get_simple_userinfo``
* ``user/getfollows/%d`` — ``offset``, ``limit``, ``order``
* ``user/grabed/status/get`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``user/guide/focus/get`` — ``resourceId``, ``userId``, ``resourceType``
* ``user/homepage/follow/recommend``
* ``user/init/playlist`` — ``type``, ``result``, ``songdata``
* ``user/iplay/info/get`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``user/lately/details/follows/get``
* ``user/lately/head/follows/get``
* ``user/location`` — ``lat``, ``lon``
* ``user/login/bginfo``
* ``user/login/cellphone/report``
* ``user/middleuserextdata/getbyattributekey`` *(inferred)*
* ``user/msg/comments/delete``
* ``user/mutualfollow/get`` — ``time``, ``threadId``, ``limit``, ``parentCommentId``, ``commentId``, ``friendid``
* ``user/page/background/setwithnoskey``
* ``user/page/pretend/info`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``user/personal/page/cansee`` — ``req``
* ``user/personal/page/info``
* ``user/playlist`` — ``uid``, ``limit``, ``offset``, ``includeVideo``, ``newStyle``
* ``user/playlist/collect`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``user/playlist/create`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``user/playlist/favorite`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``user/playlist/notice/get``
* ``user/playlist/song/category/get``
* ``user/playlist/top`` — ``id``
* ``user/playlist/top/cancel`` — ``id``
* ``user/playlist/v2`` — ``uid``, ``limit``, ``offset``, ``includeVideo``, ``includeShareStatus``, ``cpt``, ``trackIds``, ``sortType``, ``mineSortType``, ``addTrackType``
* ``user/profile/update`` — ``nickname``, ``signature``, ``gender``, ``province``, ``city``, ``birthday``
* ``user/recommend/celebrities`` — ``type``, ``limit``, ``offset``
* ``user/register/device`` *(inferred)*
* ``user/remarkname/get`` — ``friendid``, ``hint``, ``alias``, ``type``
* ``user/remarkname/set`` — ``friendid``, ``remarkname``
* ``user/replacecellphone/v2``
* ``user/replacecellphone/v4``
* ``user/screenshot/intercept``
* ``user/setting`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``user/setting/minorstate/set``
* ``user/setting/teenpattern/get`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``user/setting/teenpattern/pop/check`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``user/setting/update`` — ``shareSetting``, ``concertSetting``, ``allowNewFollowerNotify``, ``allowKtvRoomNotify``, ``allowSubscriptionNotify``, ``allowPlaylistShareNotify``, ``allowDJRadioSubscriptionNotify``, ``peopleNearbyCanSeeMe``, ``topLayerNotifySetting``, ``allowOfflineNotify``, ``allowLikedNotify``, ``needRcmdEvent``, ``phoneFriendSetting``, ``allow_video_subscription_notify``, ``canSeeFollowSingersSetting``, ``personalServiceSetting``, ``mutualFollowSeeOnline``, ``voiceAutoPlay``, ``fansRequestUpdate``, ``commentLiveBroadcastSetting``, ``open_homepage_roaming``, ``personalizedAdRecommendSwitch``, ``reduceAdSwitch``, ``messageRejectStatus``, ``showFMAtBottomTab``, ``showNoteAtBottomTab``, ``showSearchAtBottomTab``, ``showMagentAtBottomTab``
* ``user/sns/bind-and-login``
* ``user/snsfriends/new`` — ``type``, ``name``, ``uid``, ``data``
* ``user/snsfriends/v2`` — ``type``, ``name``, ``uid``, ``data``
* ``user/sub/artist/exist``
* ``user/sub/artist/get``
* ``user/tag/list``
* ``user/unbinding/check``
* ``user/unfollow/recommend/v1`` — ``addressPermission``, ``scene``, ``offset``, ``addressJsonData``
* ``user/unfollow/snsfriend/v1`` — ``authority``, ``name``, ``uid``, ``data``
* ``user/urs/sns/login``
* ``user/v2/follows/get``
* ``user/v3/follows/get``
* ``user/widget/list/get``
* ``v1/user/comments/%d`` — ``limit``, ``offset``, ``scene``
* ``v1/user/comments_tab``
* ``v1/user/detail``
* ``v1/user/detail/%d`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``v1/user/info`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``v1/user/scene_comments`` — ``limit``, ``offset``, ``scene``

listen (68)
-----------

* ``listen/live``
* ``listen/together/agora/token/get``
* ``listen/together/ask/for/vip``
* ``listen/together/avatar/pendant/batch/get``
* ``listen/together/avatar/pendant/show/get``
* ``listen/together/avatar/pendant/show/set``
* ``listen/together/common/liked/song/report``
* ``listen/together/device/reconnect/notice``
* ``listen/together/distance/get``
* ``listen/together/emoticon/get``
* ``listen/together/emoticon/report``
* ``listen/together/end/check``
* ``listen/together/end/v2``
* ``listen/together/float/activity/get``
* ``listen/together/friend/online/guide/v2``
* ``listen/together/heart/rcmd/change``
* ``listen/together/heartbeat``
* ``listen/together/invitation/reject``
* ``listen/together/invite/message/send``
* ``listen/together/listening/invite/remind/today/close``
* ``listen/together/listening/privacy/get``
* ``listen/together/listening/privacy/update``
* ``listen/together/multi/invite``
* ``listen/together/multi/match``
* ``listen/together/multi/match/ack``
* ``listen/together/multi/match/cancel``
* ``listen/together/multi/match/exit``
* ``listen/together/multi/match/heartbeat``
* ``listen/together/multi/match/msg/history``
* ``listen/together/multi/match/msg/translate/retry``
* ``listen/together/multi/match/song/operate``
* ``listen/together/multi/match/status/get``
* ``listen/together/multi/room/create``
* ``listen/together/multi/special/msg/history``
* ``listen/together/multi/special/song/operate``
* ``listen/together/multi/start/msg``
* ``listen/together/mutual/follows/get``
* ``listen/together/mutual/follows/get/v2``
* ``listen/together/notice/popup``
* ``listen/together/pat/report``
* ``listen/together/pat/setting/get``
* ``listen/together/play/command/report``
* ``listen/together/play/invitation/accept``
* ``listen/together/playlist/create/notify``
* ``listen/together/privilege/get``
* ``listen/together/relation/statistics/get/v2``
* ``listen/together/restore/reconnect/info``
* ``listen/together/room/check``
* ``listen/together/room/create``
* ``listen/together/room/songs/list``
* ``listen/together/song/listening/artist/invite/check``
* ``listen/together/song/match/ack``
* ``listen/together/song/match/cancel``
* ``listen/together/song/match/info/list``
* ``listen/together/song/match/read/report``
* ``listen/together/song/match/start``
* ``listen/together/status/get``
* ``listen/together/streak/checkin``
* ``listen/together/streak/info``
* ``listen/together/sync/list/command/report``
* ``listen/together/sync/notice``
* ``listen/together/sync/playlist/get``
* ``listen/together/user/gps/report``
* ``listen/together/user/state/config``
* ``listen/together/user/state/get``
* ``listen/together/user/state/set``
* ``listen/together/vip/gift/report``
* ``listen/together/yunxin/token/get``

mlog (65)
---------

* ``mlog/aggregation/activities/get`` — ``id``, ``v``
* ``mlog/aggregation/title/get`` — ``id``, ``v``
* ``mlog/artist/video`` — ``artistId``, ``tab``, ``size``, ``cursor``, ``page``, ``order``
* ``mlog/base``
* ``mlog/biubiu/comments`` *(inferred)*
* ``mlog/box/detail``
* ``mlog/channels/get`` *(inferred)*
* ``mlog/chart/video/rank/get`` *(inferred)*
* ``mlog/classification/song/v1`` — ``limit``, ``page``, ``scene``, ``classId``
* ``mlog/comment/guide/doc/get``
* ``mlog/delete``
* ``mlog/detail``
* ``mlog/detail/v1``
* ``mlog/draft/list``
* ``mlog/feed`` *(inferred)*
* ``mlog/feed/bff/app/v1``
* ``mlog/homepage/rec/get``
* ``mlog/intelligent/graph``
* ``mlog/location/nearby/search`` — ``keyword``, ``radius``, ``lon``, ``lat``, ``page``, ``limit``
* ``mlog/location/search`` — ``keyword``, ``page``, ``limit``, ``lon``, ``lat``
* ``mlog/mix/status/get`` — ``encMlogId``
* ``mlog/mix/status/update`` — ``encMlogId``, ``mixStatus``
* ``mlog/music/check/v1`` — ``songIds``, ``scene``
* ``mlog/music/favor/v1`` — ``limit``, ``offset``, ``scene``
* ``mlog/music/intelligent/rcmd/v1`` — ``keywords``, ``scene``
* ``mlog/music/rcmd/v1`` — ``scene``
* ``mlog/music/search/v1`` — ``keyword``, ``limit``, ``page``, ``scene``
* ``mlog/mycollect/bytime/get``
* ``mlog/mycollect/count/get``
* ``mlog/mylike/bytime/get/v1``
* ``mlog/mymlog/get/v1`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``mlog/personal``
* ``mlog/playlist/cards/get``
* ``mlog/playlist/mylike/bytime/get`` — ``limit``, ``time``
* ``mlog/playlist/song/v1`` — ``limit``, ``page``, ``scene``, ``playlistId``
* ``mlog/publish/async`` — ``templateId``
* ``mlog/publish/async/check``
* ``mlog/publish/common/config``
* ``mlog/publish/config``
* ``mlog/publish/guide/doc/get`` *(inferred)*
* ``mlog/publish/idea/mass/get``
* ``mlog/publishv2``
* ``mlog/rcmd/feed/list``
* ``mlog/rcmd/feed/list/box``
* ``mlog/rcmd/feed/list/box/similarity``
* ``mlog/rcmd/v2``
* ``mlog/rcmd/v3``
* ``mlog/related/tag``
* ``mlog/resource/collect`` — ``id``, ``type``
* ``mlog/resource/uncollect`` — ``id``, ``type``
* ``mlog/song/classification/v1`` — ``scene``
* ``mlog/song/play/block/page`` *(inferred)*
* ``mlog/song/star`` — ``star``, ``songId``, ``id``, ``type``, ``recognize``
* ``mlog/song/tsmeta`` — ``id``, ``v``
* ``mlog/song/url``
* ``mlog/songmlog/bysocre/get/v2`` — ``limit``, ``resource``, ``resourceMlogId``, ``songId``, ``offset``, ``time``
* ``mlog/songmlog/bytime/get/v2`` — ``limit``, ``resource``, ``resourceMlogId``, ``songId``, ``offset``, ``time``
* ``mlog/talk/create`` — ``name``, ``checkToken``
* ``mlog/talk/search`` — ``keywords``, ``page``, ``limit``, ``type``, ``status``, ``sortProp``
* ``mlog/talkcategory/get``
* ``mlog/talkcategory/talks/get`` — ``page``, ``circleId``, ``limit``, ``talkCategoryId``, ``mlogContext``
* ``mlog/video/rank/get``
* ``mlog/video/url``
* ``mlog/videobox`` *(inferred)*
* ``mlog/vinyl/story/list``

playlist (60)
-------------

* ``playlist/catalogue/v1``
* ``playlist/category/list`` — ``cat``, ``limit``
* ``playlist/core.db``
* ``playlist/cover/update`` — ``id``
* ``playlist/create`` — ``name``, ``privacy``, ``type``, ``checkToken``, ``trackIds``, ``shareUserIds``
* ``playlist/desc/update`` — ``id``, ``desc``, ``checkToken``
* ``playlist/detail`` — ``afterAppearOrpheus``, ``sourceTrialType``
* ``playlist/detail/dynamic`` — ``id``
* ``playlist/detail/rcmd/flag``
* ``playlist/detail/rcmd/get``
* ``playlist/highquality/list`` — ``cat``, ``lasttime``, ``limit``
* ``playlist/highquality/tags`` — ``cat``, ``lasttime``, ``limit``
* ``playlist/highquality/update`` — ``id``
* ``playlist/import/config/get``
* ``playlist/import/task/status/v2``
* ``playlist/import/url/check`` *(inferred)*
* ``playlist/list/get`` — ``ids``
* ``playlist/manipulate/tracks`` — ``op``, ``trackIds``, ``pid``, ``imme``, ``ex``, ``checkToken``
* ``playlist/mix/info``
* ``playlist/mix/info/save`` — ``fadeOutStart``, ``fadeInEnd``, ``aTransitionStartMs``, ``bTransitionEndMs``
* ``playlist/official/ids/get``
* ``playlist/offline/song/entrance/get``
* ``playlist/order/update`` — ``ids``, ``self``
* ``playlist/privilege`` — ``id``, ``n``, ``trialMode``
* ``playlist/random/list/get``
* ``playlist/rcmd/audit/status``
* ``playlist/regression/song``
* ``playlist/remove`` — ``ids``, ``self``
* ``playlist/shared/close``
* ``playlist/shared/config/get``
* ``playlist/shared/contributor/add``
* ``playlist/shared/contributor/delete`` *(inferred)*
* ``playlist/shared/contributors/get``
* ``playlist/shared/invitation/check``
* ``playlist/shared/invite``
* ``playlist/shared/open``
* ``playlist/shared/open/interact/privilege``
* ``playlist/shared/open/privilege``
* ``playlist/shared/privilege``
* ``playlist/shared/quit``
* ``playlist/shared/suspend``
* ``playlist/shared/version/check``
* ``playlist/star/song/rcmd``
* ``playlist/subscribe`` — ``id``, ``checkToken``
* ``playlist/subscriber/remove``
* ``playlist/subscribers/bytime`` — ``id``, ``limit``, ``time``
* ``playlist/tags``
* ``playlist/tags/update`` — ``id``, ``tags``
* ``playlist/track/add``
* ``playlist/track/add/pre/check``
* ``playlist/track/delete``
* ``playlist/track/reorder``
* ``playlist/update/name`` — ``id``, ``name``
* ``playlist/update/playcount`` — ``id``, ``checkToken``
* ``playlist/update/privacy``
* ``playlist/v4/detail`` — ``id``, ``n``, ``s``, ``cpt``, ``e_r``, ``cache_key``, ``shareUserId``, ``sharedInvitationId``
* ``playlist/video/recent``
* ``v1/playlist/importFromLocal`` — ``songIds``, ``playlistId``, ``playlistName``, ``cleanBeforeImport``
* ``v1/playlist/manipulate/tracks`` — ``op``, ``pid``, ``imme``, ``userActionMap``, ``ex``, ``checkToken``, ``reverse``, ``message``, ``err_push_song``
* ``v6/playlist/detail`` — ``id``, ``v``, ``c``, ``trialMode``, ``t``, ``n``, ``s``, ``shareUserId``, ``sharedInvitationId``

event (52)
----------

* ``event/artist/comment/card/get``
* ``event/artist/fans_group/board/get``
* ``event/artist/note/interact``
* ``event/board/join/notice/get``
* ``event/center/song/check`` *(inferred)*
* ``event/data/monitor/getAllSampleData`` *(inferred)*
* ``event/data/monitor/upload``
* ``event/delete`` — ``id``, ``deleteStrategy``
* ``event/detail/get/v1`` — ``id``, ``userId``
* ``event/discuss/detail/get``
* ``event/discuss/detail/publish/guide/get`` — ``actId``, ``type``
* ``event/discuss/publish`` — ``type``, ``id``, ``eventId``, ``title``, ``msg``, ``threadId``, ``uuid``, ``actId``, ``pics``, ``soundeffectsType``, ``soundeffectsId``, ``soundeffectsFeed``, ``privacySetting``, ``anonymous``, ``addComment``, ``lotteryId``, ``checkToken``, ``webviewTitle``, ``webviewSubTitle``, ``webviewRedTag``, ``webviewCoverImgUrl``, ``webviewUrl``, ``orpheusUrl``, ``extId``, ``extType``, ``circleId``, ``audioExt``, ``targetPublishTime``, ``pointTopicInfo``, ``invalidActivityName``, ``activityInfoList``, ``distributionType``, ``extSource``, ``location``, ``socialUserId``, ``socialSpaceVisible``, ``redEnvelopeInfo``, ``pubSource``
* ``event/draft``
* ``event/feed/row/rcmd/user/refresh``
* ``event/forum/gift/statistic``
* ``event/forward`` — ``forwards``, ``id``, ``eventUserId``, ``checkToken``
* ``event/forwardlist``
* ``event/get/%d`` — ``userId``, ``user_id``, ``userid``, ``time``, ``limit``, ``eventResourceType``, ``source``, ``fromRN``
* ``event/history/feed/get``
* ``event/image/segment/async`` *(inferred)*
* ``event/image/segment/async/check`` *(inferred)*
* ``event/inner/feed/get`` — ``cursor``
* ``event/privacy/op`` — ``eventId``, ``privacy``
* ``event/rcmd/reject`` — ``id``
* ``event/rcmd/topic/list`` — ``threadId``, ``source``
* ``event/red/point/follow/bubble`` — ``action``, ``tabType``
* ``event/red/point/show``
* ``event/resource/grade/get``
* ``event/search/list/get/v1``
* ``event/social/user/used/info``
* ``event/song/share/check``
* ``event/square/feed/get``
* ``event/square/feed/preload`` — ``step``, ``url``, ``reason``
* ``event/square/feed/preload/special``
* ``event/talk`` — ``fromOrpheus``, ``topIds``
* ``event/template/material/group/get`` *(inferred)*
* ``event/top/add`` — ``eventId``, ``topStatus``
* ``event/top/delete`` — ``eventId``, ``topStatus``
* ``event/top/get`` — ``userId``
* ``event/user/collect/count/get``
* ``event/user/note/music/play/privacy/setting/allow``
* ``event/user/permission`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``event/user/publisher/config``
* ``event/user/rcmd/reject`` — ``eventid``, ``actid``, ``eventId``, ``artistId``, ``userid``, ``id``, ``reason``, ``type``
* ``event/user/rcmd/total/reject`` — ``eventid``, ``actid``, ``eventId``, ``artistId``, ``userid``, ``id``, ``reason``, ``type``
* ``event/user/rcmd/v3``
* ``event/user/setting``
* ``event/video/setting``
* ``event/vinyl/bubble/action``
* ``v1/event/%d/%d`` — ``sourceScene``
* ``v2/event/get``
* ``v4/event/get`` — ``adextjson``

music (44)
----------

* ``music/audio/match/similar``
* ``music/audio/match/song/honor/info``
* ``music/basic/sound/device/get``
* ``music/dislike/change``
* ``music/dislike/get``
* ``music/file/check`` *(inferred)*
* ``music/file/config`` *(inferred)*
* ``music/file/match`` — ``rawdatas``, ``artist``, ``album``, ``songName``, ``scene``, ``sessionId``, ``decrypt``, ``duration``
* ``music/freetalk/im/chatroom/addr/request`` *(inferred)*
* ``music/growth/channel/widgets/heart/beat/get``
* ``music/intimates/desktop/get``
* ``music/matcher/feedback/add`` — ``nosKey``, ``algorithmCode``, ``songIds``, ``msg``, ``type``, ``sessionId``, ``scene``
* ``music/matcher/history/delete``
* ``music/matcher/history/delete/all``
* ``music/multi/terminal/devcie/playlist/rcmd``
* ``music/multi/terminal/global/popup/earphone/device/detail``
* ``music/multi/terminal/global/popup/earphone/device/list``
* ``music/multi/terminal/iot/device/list``
* ``music/multi/terminal/soundbox/bound/list`` *(inferred)*
* ``music/multi/terminal/tuning/nos/save``
* ``music/multi/terminal/widget/24/comment/calendar``
* ``music/multi/terminal/widget/guide/info``
* ``music/multi/terminal/widget/listen/data``
* ``music/partner/title/get``
* ``music/sheet/download/info`` — ``id``
* ``music/sheet/privilege`` — ``musicSheetIds``
* ``music/song/sheet/entry`` — ``songId``
* ``music/songshare/free/play/check`` — ``shareToken``
* ``music/songshare/free/share/used``
* ``music/songshare/linktext/recommend/get`` — ``songId``
* ``music/songshare/share/channel/list``
* ``music/songshare/share/count/add``
* ``music/songshare/share/property``
* ``music/songshare/share/wx/status`` — ``songId``
* ``music/songshare/song/tag/get``
* ``music/songshare/song/text/anti/check``
* ``music/songshare/song/text/editor/permissions/get``
* ``music/songshare/text/recommend/get``
* ``music/voice/play/report``
* ``music/voice/play/report/control``
* ``music/voice/sdk/result/get`` — ``token``, ``songId``, ``playMode``, ``seekProgress``, ``param``
* ``music/voice/sdk/token/get``
* ``music/voicebook/listen/activity/floating/window/get``
* ``v1/music/matcher/history``

dj (39)
-------

* ``dj/ai/rec/podcast/entrance/setting``
* ``dj/around/program/v1``
* ``dj/classic/voice/list``
* ``dj/follow/info``
* ``dj/manipulate/voices`` *(inferred)*
* ``dj/play/corner/entrance/get``
* ``dj/play/data/url/get``
* ``dj/play/url/v2/check``
* ``dj/playrecord/program/get``
* ``dj/playrecord/radio/get`` — ``limit``, ``offset``, ``radioId``, ``asc``, ``updateOrder``
* ``dj/playrecord/upload``
* ``dj/program/batch/detail``
* ``dj/program/danmaku/guide/info/get``
* ``dj/program/danmaku/heatmap/info/get``
* ``dj/program/danmaku/highlight/info/get`` *(inferred)*
* ``dj/program/danmaku/praise``
* ``dj/program/danmaku/wild/list``
* ``dj/program/detail`` — ``id``
* ``dj/program/list``
* ``dj/program/listen`` — ``id``
* ``dj/program/materials/v1``
* ``dj/program/song/musics`` — ``ids``
* ``dj/program/special/tags``
* ``dj/program/xiayi/detail``
* ``dj/radio/category/list`` *(inferred)*
* ``dj/radio/category/radio/list`` *(inferred)*
* ``dj/radio/like/materials/get``
* ``dj/radio/program/search``
* ``dj/rcmd/program/for/playlist``
* ``dj/user/setting/resumeplay/get``
* ``dj/user/setting/resumeplay/update``
* ``dj/vipradio/price/get``
* ``dj/voice/collect``
* ``dj/voice/show/ctrl/check``
* ``dj/voices/download/check``
* ``v1/dj/program/byradio`` — ``limit``, ``offset``, ``radioId``, ``asc``, ``updateOrder``
* ``v1/dj/program/tracks`` — ``id``
* ``v4/dj/program/byradio``
* ``v5/dj/program/byradio``

song (38)
---------

* ``song/artist/stick``
* ``song/beat/detail``
* ``song/cache/clean/get`` — ``songIds``
* ``song/chorus``
* ``song/copyright/rcmd`` — ``songid``
* ``song/enhance/%s/mv/url`` — ``id``, ``r``
* ``song/enhance/download/mv/url`` — ``id``, ``r``, ``sp``
* ``song/enhance/download/url/v1`` — ``id``, ``level``, ``immerseType``, ``effects``, ``supportDolby``, ``sp``, ``expParams``, ``ringtone``
* ``song/enhance/info/get`` — ``ids``
* ``song/enhance/location/info``
* ``song/enhance/player/url/v1`` — ``ids``, ``level``, ``encodeType``, ``trialMode``, ``faql``, ``sceneParams``
* ``song/enhance/privilege`` — ``ids``, ``trialMode``, ``trialModes``, ``trialExtraParams``
* ``song/feature/detail``
* ``song/free/trial/info``
* ``song/grey/rcmd`` — ``songid``
* ``song/like`` — ``like``, ``trackId``, ``userid``, ``userActionMap``, ``sceneParams``, ``checkToken``
* ``song/like/change`` — ``checkPoint``
* ``song/like/get``
* ``song/lyric``
* ``song/lyric/comment/entry/check``
* ``song/lyric/v1`` — ``id``, ``cp``
* ``song/more/artist/award/info/query`` — ``songId``
* ``song/music/batch/detail/get`` *(inferred)*
* ``song/music/detail/get``
* ``song/music/info/query``
* ``song/other/message``
* ``song/other/message/sheet``
* ``song/play/badcase/report/post``
* ``song/play/more/list/v2`` — ``clientLibraAbTest``, ``aidjExist``, ``fastPlayDjSwitch``, ``fastPlayHasDj``, ``lightBubbleExist``, ``ugcObj``, ``songMoreResSubType``, ``sharkBabyGroup``, ``currentTabList``, ``new_firstvisit_playbeforelogin_1019``
* ``song/play/user/personal/items`` — ``sharkBabyGroup``, ``currentTabList``
* ``song/private_domain/get`` *(inferred)*
* ``song/privilege/music/url/info/query``
* ``song/red/count``
* ``song/studio/get``
* ``song/toast`` — ``id``, ``extPlay``
* ``song/type/detail/get``
* ``song/wrapper/md5``
* ``v3/song/detail`` — ``id``, ``v``, ``c``, ``rv``, ``sourceIdMap``, ``source``, ``trialMode``, ``trialExtraParams``

search (34)
-----------

* ``search/circle/get``
* ``search/classical/page`` — ``keyword``, ``scene``, ``channel``, ``limit``, ``offset``, ``rqrefer``, ``needCorrect``, ``bizQueryInfo``
* ``search/click/rec``
* ``search/complex/get/v2``
* ``search/complex/page`` — ``keyword``, ``scene``, ``channel``, ``needCorrect``, ``newStyle``, ``page``, ``ignoreBlocks``, ``traceId``, ``cursor``, ``bizQueryInfo``, ``rqrefer``, ``hasLookApp``, ``network``, ``libraExp``, ``extInfo``, ``tagSelectSongTagInfoMap``, ``adextjson``
* ``search/complex/rec/song/get``
* ``search/default/keyword/get/v2``
* ``search/default/keyword/list`` — ``positionCode``, ``limit``, ``type``, ``lastQuery``, ``oaid``, ``deviceExtInfo``, ``nowPlaying``
* ``search/defaultkeyword/get``
* ``search/localsong/upload``
* ``search/match/new`` — ``type``, ``result``, ``songdata``
* ``search/mlog/get`` — ``keyword``, ``limit``, ``offset``, ``scene``, ``tag``, ``sort``, ``publishTime``, ``duration``, ``rqrefer``, ``channel``, ``bizQueryInfo``
* ``search/resource/lyric`` — ``keyword``, ``limit``, ``offset``, ``scene``, ``bizQueryInfo``, ``channel``, ``rqrefer``
* ``search/resource/mlog/videoplaylist`` — ``keyword``, ``limit``, ``offset``
* ``search/result/tab``
* ``search/song/list/page``
* ``search/song/page``
* ``search/specialkeyword/get``
* ``search/suggest/keyword`` — ``limit``, ``s``, ``type``, ``lastKeyword``, ``lastTime``
* ``search/suggest/keyword/get`` — ``keyword``
* ``search/topic/get``
* ``search/total/block/get`` — ``keyword``, ``blockCode``, ``scene``, ``channel``, ``needCorrect``, ``newStyle``, ``traceId``, ``bizQueryInfo``, ``rqrefer``, ``hasLookApp``, ``network``, ``tagSelectSongTagInfo``, ``libraExp``, ``extInfo``, ``limit``
* ``search/video/tag/get`` — ``keyword``
* ``search/voice/asr/auth``
* ``search/voice/get``
* ``search/voice/youdao/asr/auth``
* ``search/voicelist/get``
* ``v1/search/album/get``
* ``v1/search/artist/get``
* ``v1/search/get``
* ``v1/search/get/teenager`` — ``s``, ``sub``, ``limit``, ``checkToken``, ``offset``, ``queryCorrect``, ``keyword``, ``strategy``, ``type``, ``bizQueryInfo``, ``newStyle``, ``rqrefer``, ``channel``, ``filterCode``, ``extInfo``, ``q_scene``
* ``v1/search/playlist/get``
* ``v1/search/song/get``
* ``v1/search/user/get``

ad (32)
-------

* ``ad/action`` — ``location``, ``adId``, ``reqId``, ``action``, ``adextjson``, ``actionReason``
* ``ad/commonconfig``
* ``ad/config``
* ``ad/config/get``
* ``ad/device/deviceid``
* ``ad/device/info/upload`` — ``oaid``
* ``ad/dislike`` — ``location``, ``adId``, ``reqId``, ``adextjson``
* ``ad/dp_wechat``
* ``ad/feedback`` — ``devInfo``
* ``ad/get`` — ``type_ids``, ``xHeaderTraceId``, ``position``
* ``ad/get-200001_0`` — ``adextjson``, ``threadId``
* ``ad/listening/rights/gain``
* ``ad/listening/rights/qualification``
* ``ad/loading/bidget`` — ``adextjson``
* ``ad/loading/current`` — ``adextjson``
* ``ad/loading/currentplus`` — ``adextjson``
* ``ad/loading/get`` — ``adextjson``
* ``ad/materialconfig``
* ``ad/monitor/click`` — ``dev_info``, ``ad_data``
* ``ad/monitor/conversion``
* ``ad/monitor/impress`` — ``dev_info``, ``ad_data``
* ``ad/monitor/incentive/video``
* ``ad/monitor/mcomment/user`` — ``adUserData``, ``devInfo``
* ``ad/monitor/video`` — ``dev_info``, ``ad_data``, ``video_data``
* ``ad/order/common/change/report``
* ``ad/prefetch/select``
* ``ad/preview/enable``
* ``ad/right/direct/gain/req``
* ``ad/right/need/show/clear``
* ``ad/sniffing``
* ``ad/start/info/upload`` — ``oaid``, ``orpheus``, ``firstActive``
* ``ad/wrap/control`` — ``appName``, ``packageName``, ``version``, ``downloadSize``, ``fullSize``

homepage (31)
-------------

* ``homepage/applets/my/user/update``
* ``homepage/applets/recent/user/del``
* ``homepage/applets/user/page``
* ``homepage/ark/tab/redpoint``
* ``homepage/ark/tab/redpoint/eliminate`` — ``tabIds``
* ``homepage/banner/ad/get`` — ``adextjson``, ``extInfo``
* ``homepage/block/click``
* ``homepage/block/dislike``
* ``homepage/block/dragon/ball/guide/get``
* ``homepage/block/feedback/get``
* ``homepage/block/like``
* ``homepage/block/page``
* ``homepage/block/page/unlimited/flow``
* ``homepage/block/pin``
* ``homepage/block/resource/dislike`` — ``targetId``, ``filter``, ``alg``, ``logInfo``, ``targetType``, ``blockCode``, ``abInfo``, ``dislikeReasonType``, ``dislikeTargetId``, ``extInfo``
* ``homepage/block/resource/dislike/reason``
* ``homepage/category/daily/song/list``
* ``homepage/content/cancel/subscribe`` — ``channel``, ``ids``
* ``homepage/content/get/subscribed`` — ``channel``, ``ids``
* ``homepage/content/subscribe``
* ``homepage/daily/song/config/get``
* ``homepage/daily/song/tag/save``
* ``homepage/miniprogram/collect``
* ``homepage/miniprogram/entrance/list/v2``
* ``homepage/miniprogram/entrance/list/v3``
* ``homepage/more/rcmd/song``
* ``homepage/scene/more/rcmd/song``
* ``homepage/top/introduction/close``
* ``homepage/top/introduction/get``
* ``homepage/top/message``
* ``homepage/video/lyric/get`` — ``type``, ``songId``, ``resourceId``, ``extJson``

resource (30)
-------------

* ``resource/comment/floor/list/get``
* ``resource/comment/musiciansaid/authors`` — ``resourceid``, ``type``, ``threadId``, ``checkSyncEvent``, ``source``, ``voiceExposure``
* ``resource/comment/musiciansaid/invitation/add``
* ``resource/commentInfo/list``
* ``resource/comments/delete`` — ``threadId``, ``resourceType``, ``resourceId``, ``commentId``
* ``resource/comments/musiciansaid/get`` — ``resourceId``, ``resourceType``, ``limit``, ``beforeTime``, ``compareUserLocation``, ``showInner``, ``pageNum``, ``commentId``, ``thread_id``, ``threadid``, ``threadId``, ``hot``, ``latest``, ``current``, ``concertInfo``, ``subjectInfo``, ``festivalInfo``, ``general``, ``live``, ``vip_rcmd``, ``live_rcmd``, ``recent_hot``, ``musician``, ``comment_live``
* ``resource/comments/reply/preload`` — ``threadId``, ``commentIds``
* ``resource/like`` — ``threadId``, ``commentId``, ``checkToken``
* ``resource/privacy/setting/list``
* ``resource/unlike`` — ``threadId``, ``commentId``, ``checkToken``
* ``v1/resource/commentInfo``
* ``v1/resource/commentinfo/likelist``
* ``v1/resource/comments`` — ``resourceId``, ``resourceType``, ``limit``, ``beforeTime``, ``compareUserLocation``, ``composeConcert``, ``pageNum``, ``commentId``, ``hot``, ``latest``, ``top``, ``current``
* ``v1/resource/comments/add`` — ``threadId``, ``resourceType``, ``resourceId``, ``lyricComment``, ``expressionPicId``, ``forwardEvent``, ``anonym``, ``socialUserId``, ``bubbleId``, ``checkToken``, ``voiceNosKey``, ``voiceWhaleId``, ``voiceDurationMillSecond``, ``pubExtInfo``, ``voiceClientExtInfo``, ``publishMode``, ``contentPicNosKey``, ``richContent``, ``scene``, ``grade``, ``gradeSnapshotId``, ``gradeStandard``, ``contentResourceId``, ``contentResourceType``, ``source``, ``topicIds``, ``topicNames``, ``privacySetting``, ``preCommentId``
* ``v1/resource/comments/config``
* ``v1/resource/comments/mention/policy/get``
* ``v1/resource/comments/preallocate``
* ``v1/resource/comments/publish/view`` — ``songId``
* ``v1/resource/comments/reply`` — ``threadId``, ``resourceType``, ``resourceId``, ``checkToken``, ``commentId``, ``lyricComment``, ``expressionPicId``, ``forwardEvent``, ``anonym``, ``socialUserId``, ``bubbleId``, ``voiceNosKey``, ``voiceWhaleId``, ``voiceDurationMillSecond``, ``pubExtInfo``, ``voiceClientExtInfo``, ``publishMode``, ``singJoinCommentId``, ``contentPicNosKey``, ``richContent``, ``source``, ``scene``, ``preCommentId``
* ``v1/resource/comments/voice/ext``
* ``v1/resource/hotcomments/%s`` — ``limit``, ``offset``
* ``v2/resource/comment/floor/get`` — ``cursor``, ``time``, ``threadId``, ``limit``, ``parentCommentId``, ``commentId``, ``order``, ``source``, ``topCommentIds``, ``scene``
* ``v2/resource/comments`` — ``threadId``, ``cursor``, ``sortType``, ``pageSize``, ``showInner``, ``pageNo``, ``scene``
* ``v2/resource/comments/hug/list``
* ``v2/resource/comments/hug/listener``
* ``v2/resource/comments/hug/rights`` — ``threadId``
* ``v2/resource/comments/preload`` — ``threadId``, ``cursor``, ``sortType``, ``pageSize``, ``showInner``, ``pageNo``, ``parentCommentId``, ``preloadExpGroupName``, ``commentId``, ``topCommentId``, ``scene``, ``debugTraceId``
* ``v2/resource/comments/preload/exposure``
* ``v2/resource/comments/preload/strategy``
* ``v2/resource/more/recommend/comments``

comment (28)
------------

* ``comment/default/text``
* ``comment/detail/v2``
* ``comment/dislike``
* ``comment/dislike/cancel``
* ``comment/expression/list``
* ``comment/expression/startusing/v1`` — ``id``
* ``comment/favorite/toggle``
* ``comment/feed/inserted/resources``
* ``comment/feed/inserted/resources/combined``
* ``comment/feed/inserted/resources/isolation``
* ``comment/guide`` — ``resourceid``, ``type``, ``threadId``, ``checkSyncEvent``, ``source``, ``voiceExposure``
* ``comment/hotcomment/collect/fetchmodelinfov2``
* ``comment/hotwall/today/squareinfo/get``
* ``comment/owner/delete/permission``
* ``comment/permission/query``
* ``comment/privacy/op``
* ``comment/recenthotcomment/get`` — ``resourceId``, ``resourceType``, ``limit``, ``beforeTime``, ``compareUserLocation``, ``showInner``, ``pageNum``, ``commentId``, ``thread_id``, ``threadid``, ``threadId``, ``hot``, ``latest``, ``current``, ``concertInfo``, ``subjectInfo``, ``festivalInfo``, ``general``, ``live``, ``vip_rcmd``, ``live_rcmd``, ``recent_hot``, ``musician``, ``comment_live``
* ``comment/resource/generalinfo/get``
* ``comment/tips/v2/get`` — ``resourceid``, ``type``, ``threadId``, ``checkSyncEvent``, ``source``, ``voiceExposure``
* ``comment/user/auth/comment/forbid``
* ``comment/user/auth/exist``
* ``comment/user/auth/get``
* ``comment/user/comment/history`` — ``compose_hot_comment``, ``compose_reminder``, ``limit``, ``time``, ``user_id``
* ``comment/user/comment/newsend`` — ``user_id``
* ``comment/user/commentcount`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``comment/user/operate`` — ``threadId``, ``commentId``, ``optType``
* ``v1/comment/like`` — ``threadId``, ``commentId``, ``checkToken``
* ``v1/comment/unlike`` — ``threadId``, ``commentId``, ``checkToken``

mlivestream (26)
----------------

* ``mlivestream/accompaniment/intonation/config`` *(inferred)*
* ``mlivestream/accompaniment/intonation/score/upload`` *(inferred)*
* ``mlivestream/accompaniment/intonation/time/delay`` *(inferred)*
* ``mlivestream/accompaniment/operation/v3`` *(inferred)*
* ``mlivestream/accompaniment/search/v2`` — ``keyword``, ``limit``, ``offset``
* ``mlivestream/ad/spread/report`` *(inferred)*
* ``mlivestream/anchor/start-stream/entrance`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``mlivestream/collect/zan/anchor/clear`` *(inferred)*
* ``mlivestream/entrance/native/common/live/list`` *(inferred)*
* ``mlivestream/entrance/new/user/pop``
* ``mlivestream/entrance/playpage/choose/song``
* ``mlivestream/entrance/playpage/playback/get`` *(inferred)*
* ``mlivestream/entrance/playpage/playback/more`` *(inferred)*
* ``mlivestream/entrance/playpage/v7/get``
* ``mlivestream/entrance/playrecord/clear`` *(inferred)*
* ``mlivestream/entrance/playrecord/list`` *(inferred)*
* ``mlivestream/entrance/radio/details/get/v1``
* ``mlivestream/live/spread/outside/callback`` *(inferred)*
* ``mlivestream/mlog/dislike/config``
* ``mlivestream/mlog/dislike/config/v2`` *(inferred)*
* ``mlivestream/mlog/dislike/upload`` *(inferred)*
* ``mlivestream/pipe/anchor/singing/check`` *(inferred)*
* ``mlivestream/pipe/common/anchor/get`` *(inferred)*
* ``mlivestream/pipe/common/live/get`` *(inferred)*
* ``mlivestream/pipe/hot/song/rank/anchor/singing/recmd/get`` *(inferred)*
* ``mlivestream/room/type/msg``

voice (24)
----------

* ``v1/voice/comments/preupload`` — ``threadId``, ``parentCommentId``, ``voiceNosKey``, ``voiceWhaleId``, ``voiceDurationMillSecond``, ``pubExtInfo``
* ``v1/voice/comments/voice-change/create``
* ``v1/voice/comments/voice-change/status``
* ``voice/alg/skip/info/get``
* ``voice/alg/skip/switch/get``
* ``voice/book/coupon/unlock``
* ``voice/book/share/note/image/refresh`` — ``imageUrl``, ``startTime``, ``endTime``, ``imageId``
* ``voice/book/share/note/material``
* ``voice/book/share/note/material/stats`` — ``imageUrl``, ``startTime``, ``endTime``, ``imageId``
* ``voice/broadcast/channel/currentinfo`` — ``channelId``, ``refreshPlayUrl``
* ``voice/detail/ext``
* ``voice/homepage/block/page``
* ``voice/lyric/get`` *(inferred)*
* ``voice/note/task/detail`` *(inferred)*
* ``voice/note/task/submit`` *(inferred)*
* ``voice/play/page/ad/info``
* ``voice/play/page/rcmd``
* ``voice/play/share/template/get`` *(inferred)*
* ``voice/publish/check``
* ``voice/publish/privilege/get`` *(inferred)*
* ``voice/punch/card/guide/content``
* ``voice/record``
* ``voice/share/edit/list``
* ``voice/track/feedback``

artist (23)
-----------

* ``artist/albums/%d`` — ``limit``, ``offset``
* ``artist/albums/bytype`` — ``artist_id``, ``limit``, ``index``, ``sort``
* ``artist/all`` — ``offset``, ``limit``, ``initial``, ``categoryCode``
* ``artist/detail/dynamic`` — ``userId``
* ``artist/detail/dynamic/v2`` — ``artistId``, ``resourceParam``
* ``artist/fans/get``
* ``artist/follow/count/get`` — ``userId``
* ``artist/get/product/list``
* ``artist/head/info/get`` — ``userId``
* ``artist/hot`` — ``offset``, ``limit``, ``initial``
* ``artist/page/anchor/route`` — ``userId``
* ``artist/page/annual/fans/popup/window/issue``
* ``artist/personal/edit/route/page`` — ``userId``
* ``artist/set/product/list``
* ``artist/song/count`` — ``artistId``, ``id``, ``type``, ``resourcePosition``, ``resourceId``, ``resourceParam``, ``profileId``
* ``artist/sub/batch``
* ``artist/unsub`` — ``artistId``, ``checkToken``, ``jsonrefer``, ``artistIds``, ``rqRefer``
* ``artist/user/noticeswitch/get`` — ``artistUserId``, ``artistId``
* ``artist/user/noticeswitch/update``
* ``artist/video``
* ``v1/artist/sub`` — ``artistId``, ``checkToken``
* ``v1/artist/top/song``
* ``v2/artist/songs`` — ``id``, ``limit``, ``offset``, ``private_cloud``, ``work_type``, ``order``

usertool (22)
-------------

* ``usertool/home/sound/info`` *(inferred)*
* ``usertool/home/soundeffect/devicebrand/list``
* ``usertool/home/soundeffect/devicesound/default/get``
* ``usertool/home/soundeffect/devicesound/list``
* ``usertool/home/soundeffect/devicesound/offical/list``
* ``usertool/home/soundeffect/feed/hotmessage/list`` — ``soundType``, ``soundId``, ``id``, ``pageNo``, ``pageSize``
* ``usertool/home/soundeffect/feed/message/list`` — ``soundType``, ``soundId``, ``id``, ``pageNo``, ``pageSize``
* ``usertool/ksong/song/check``
* ``usertool/ring/song/check``
* ``usertool/share/wechat/applet/picture/app``
* ``usertool/sign/config``
* ``usertool/smart/sound/get``
* ``usertool/sound/material`` — ``type``, ``id``
* ``usertool/sound/mobile/all``
* ``usertool/sound/mobile/animationList``
* ``usertool/sound/mobile/count``
* ``usertool/sound/mobile/detail`` — ``soundType``, ``soundId``, ``id``, ``pageNo``, ``pageSize``
* ``usertool/sound/mobile/promote`` — ``moduleName``
* ``usertool/sound/mobile/theme``
* ``usertool/sound/mobile/whalecloudnewadd``
* ``usertool/sound/twinkle/all`` — ``moduleName``
* ``usertool/sound/twinkle/detail`` — ``soundType``, ``soundId``, ``id``, ``pageNo``, ``pageSize``

cloud (20)
----------

* ``cloud/account/version/get`` *(inferred)*
* ``cloud/del`` — ``songIds``
* ``cloud/file/download/get`` *(inferred)*
* ``cloud/file/upload/cancel``
* ``cloud/file/upload/check`` — ``fileName``, ``fileSize``, ``fileMd5``, ``files``
* ``cloud/file/upload/create`` — ``fileName``, ``fileSize``, ``fileMd5``, ``fileNosKey``
* ``cloud/file/upload/status``
* ``cloud/file/user/config/get``
* ``cloud/guide/get``
* ``cloud/lyric/get`` — ``songId``, ``userId``, ``kv``, ``lv``
* ``cloud/mobile/drive/file/playUrl`` *(inferred)*
* ``cloud/pub/v2``
* ``cloud/record/get`` — ``recordIds``
* ``cloud/upload/check/v2``
* ``cloud/user/menu/get``
* ``cloud/user/settings/upload/set``
* ``cloud/user/song/import`` — ``songId``, ``bitrate``, ``song``, ``artist``, ``album``, ``fileName``
* ``v1/cloud/music/status``
* ``v1/cloud/sort/update``
* ``v3/cloud/get`` — ``limit``

djradio (20)
------------

* ``djradio/buyprogram`` — ``radioId``, ``programIds``, ``payMethod``, ``payType``, ``from``, ``tradeAmountType``, ``ext``
* ``djradio/buyradio`` — ``radioId``, ``payMethod``, ``payType``, ``from``, ``tradeAmountType``, ``buyType``, ``ext``
* ``djradio/carfm/get`` — ``radio1``, ``radio1More``, ``radio2More``
* ``djradio/get`` — ``id``
* ``djradio/get/byuser/v1`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``djradio/my/radio/recommend``
* ``djradio/newcount/clear/byradio`` — ``radioId``
* ``djradio/notify/confirm``
* ``djradio/notify/status/get``
* ``djradio/order/unbuy/programs/get`` — ``radioId``, ``page``, ``size``
* ``djradio/pic`` — ``id``
* ``djradio/sub`` — ``id``, ``sourceMap``, ``checkToken``
* ``djradio/subscribe/state/batch/get``
* ``djradio/subscriber`` — ``id``, ``time``, ``limit``
* ``djradio/tab/query`` *(inferred)*
* ``djradio/unsub`` — ``id``, ``sourceMap``, ``checkToken``
* ``djradio/v3/get``
* ``djradio/v4/get`` *(inferred)*
* ``djradio/v5/adaptive`` *(inferred)*
* ``djradio/v5/resume/point``

discovery (15)
--------------

* ``discovery/ark``
* ``discovery/new/albums`` — ``year``, ``month``
* ``discovery/newsongalbum`` — ``afterAppearOrpheus``, ``sourceTrialType``
* ``discovery/playlistTalentList``
* ``discovery/recommend/newsongs`` — ``areaId``
* ``discovery/recommend/songs/history/detail``
* ``discovery/recommend/songs/history/recent``
* ``discovery/simiPlaylist``
* ``discovery/simiUser``
* ``discovery/topNewUserList``
* ``v1/discovery/simiSong``
* ``v2/discovery/new/songs`` — ``areaId``
* ``v2/discovery/recommend/dislike`` — ``resType``, ``resId``, ``sceneType``, ``orderId``, ``extParam``
* ``v2/discovery/recommend/songs``
* ``v3/discovery/recommend/songs`` — ``ispush``

login (15)
----------

* ``login`` — ``username``, ``password``, ``api``
* ``login/ban``
* ``login/cellphone`` — ``loginType``, ``ursToken``, ``nonce``, ``checkToken``, ``phone``, ``countrycode``, ``password``, ``secureCaptcha``, ``mCellphone``, ``mRegionCode``, ``token``, ``type``, ``response``, ``status``
* ``login/cellphone/twice/used/confirm``
* ``login/citd``
* ``login/getquickloginlist`` — ``userInfoList``, ``currentEnv``, ``checkToken``
* ``login/password/update``
* ``login/qrcode/server/login`` — ``key``, ``type``, ``userid``, ``checkToken``, ``clientTraceId``, ``url``
* ``login/quicklogin`` — ``userInfoList``, ``currentEnv``, ``targetUserId``, ``checkToken``
* ``login/relogin``
* ``login/sns``
* ``login/switchuser`` — ``userInfoList``, ``currentEnv``, ``targetUserId``, ``checkToken``, ``currentUserId``
* ``login/token/findlasttoken``
* ``login/token/refresh`` — ``clientUserId``, ``ydDeviceToken``, ``checkToken``, ``userId``, ``token``, ``model``, ``os``, ``cost``, ``signParams``, ``sign``
* ``login/token/refresh/v1`` — ``clientUserId``, ``ydDeviceToken``, ``checkToken``, ``userId``, ``token``, ``model``, ``os``, ``cost``, ``signParams``, ``sign``

follow (14)
-----------

* ``follow/listen/create/room``
* ``follow/listen/device/reconnect/notice``
* ``follow/listen/join/room``
* ``follow/listen/room/exit``
* ``follow/listen/room/heartbeat``
* ``follow/listen/room/playlist/change``
* ``follow/listen/room/playlist/operate``
* ``follow/listen/room/playlist/wait/page``
* ``follow/listen/room/rcmd/list``
* ``follow/listen/room/song/like``
* ``follow/listen/room/song/operate``
* ``follow/listen/room/song/zan``
* ``follow/listen/status/get``
* ``follow/listen/user/rcmd/song``

clientlog (12)
--------------

* ``clientlog``
* ``clientlog/batch/fast``
* ``clientlog/encrypt/upload``
* ``clientlog/encrypt/upload/fastaction``
* ``clientlog/encrypt/upload/monitor``
* ``clientlog/encrypt/upload/sysaction``
* ``clientlog/encrypt/upload/v2``
* ``clientlog/mam``
* ``clientlog/mam/upload``
* ``clientlog/upload``
* ``clientlog/upload/fastaction``
* ``clientlog/upload/sysaction``

icreator (12)
-------------

* ``icreator/asr/audio/analyze`` *(inferred)*
* ``icreator/material/category/get`` *(inferred)*
* ``icreator/material/get`` *(inferred)*
* ``icreator/material/homepage`` *(inferred)*
* ``icreator/search/song`` *(inferred)*
* ``icreator/search/suggest`` *(inferred)*
* ``icreator/search/tag`` *(inferred)*
* ``icreator/song/play/info`` *(inferred)*
* ``icreator/song/playlist`` *(inferred)*
* ``icreator/song/recommend`` *(inferred)*
* ``icreator/song/star`` *(inferred)*
* ``icreator/tag/list`` *(inferred)*

sociallive (12)
---------------

* ``sociallive/chatbot/content/to/text`` *(inferred)*
* ``sociallive/game/guess/draw/answer`` *(inferred)*
* ``sociallive/game/guess/playing/answer`` *(inferred)*
* ``sociallive/game/guess/playing/prepare`` *(inferred)*
* ``sociallive/game/guess/playing/status/get`` *(inferred)*
* ``sociallive/game/song/play/info/get`` *(inferred)*
* ``sociallive/guess/draw/board/get`` *(inferred)*
* ``sociallive/guess/draw/board/push`` *(inferred)*
* ``sociallive/guess/draw/resonance/change`` *(inferred)*
* ``sociallive/guess/resonance/bubble/send`` *(inferred)*
* ``sociallive/guess/result/get`` *(inferred)*
* ``sociallive/guess/user/get`` *(inferred)*

album (11)
----------

* ``album/ban/get``
* ``album/detail/dynamic``
* ``album/new``
* ``album/play`` — ``id``
* ``album/privilege`` — ``id``
* ``album/purchase/display``
* ``album/sub`` — ``id``, ``checkToken``
* ``album/sublist``
* ``album/unsub`` — ``id``, ``checkToken``
* ``album/v3/detail`` — ``e_r``, ``id``, ``cache_key``
* ``album/v4/detail`` — ``e_r``, ``id``, ``cache_key``

topic (11)
----------

* ``topic/all`` — ``seriesId``, ``limit``, ``offset``
* ``topic/category/hot/list`` — ``categoryid``, ``limit``, ``offset``, ``pubtime``
* ``topic/category/time/list`` — ``categoryid``, ``limit``, ``offset``, ``pubtime``
* ``topic/hot``
* ``topic/index/category/list``
* ``topic/selected/list`` — ``limit``, ``pubtime``
* ``topic/series/byuser`` — ``userId``, ``user_id``, ``reminder``, ``userid``
* ``topic/sub`` — ``id``, ``checkToken``
* ``topic/sublist``
* ``topic/thread`` — ``threadId``, ``limit``, ``offset``
* ``topic/unsub`` — ``id``, ``checkToken``

vipauth (11)
------------

* ``vipauth/app/auth/query``
* ``vipauth/app/auth/recycle``
* ``vipauth/app/auth/soundquality/andriod/query``
* ``vipauth/app/birthday-call/interest-material`` *(inferred)*
* ``vipauth/app/interests/material/bubble/room`` *(inferred)*
* ``vipauth/app/interests/material/list`` *(inferred)*
* ``vipauth/app/interests/use/batch-interests/report`` *(inferred)*
* ``vipauth/app/interests/use/single-interests/report`` *(inferred)*
* ``vipauth/app/interests/userrecord/get`` *(inferred)*
* ``vipauth/app/pet/model/resources`` *(inferred)*
* ``vipauth/memberlogo/identity`` *(inferred)*

content (10)
------------

* ``content/exposure/comment/banner/get`` — ``resourceId``, ``resourceType``, ``limit``, ``beforeTime``, ``compareUserLocation``, ``showInner``, ``pageNum``, ``commentId``, ``thread_id``, ``threadid``, ``threadId``, ``hot``, ``latest``, ``current``, ``concertInfo``, ``subjectInfo``, ``festivalInfo``, ``general``, ``live``, ``vip_rcmd``, ``live_rcmd``, ``recent_hot``, ``musician``, ``comment_live``
* ``content/exposure/comment/get`` — ``resourceId``, ``resourceType``, ``limit``, ``beforeTime``, ``compareUserLocation``, ``showInner``, ``pageNum``, ``commentId``, ``thread_id``, ``threadid``, ``threadId``, ``hot``, ``latest``, ``current``, ``concertInfo``, ``subjectInfo``, ``festivalInfo``, ``general``, ``live``, ``vip_rcmd``, ``live_rcmd``, ``recent_hot``, ``musician``, ``comment_live``
* ``content/exposure/comment/resource/get``
* ``content/exposure/songplay/entrance/ksong``
* ``content/my/collect/voice``
* ``content/my/created/voicelist``
* ``content/user/creator/statistics``
* ``content/voicelist/insert/voice`` *(inferred)*
* ``content/voicelist/sub/statistics``
* ``v1/content/exposure/comment/banner/get`` — ``sourceScene``, ``time``, ``threadId``, ``limit``, ``parentCommentId``, ``commentId``, ``order``, ``source``, ``cursor``, ``topCommentIds``, ``scene``, ``friendid``, ``adextjson``, ``network``

middle (10)
-----------

* ``middle/account/cellphone/login`` *(inferred)*
* ``middle/account/sns/bind`` *(inferred)*
* ``middle/account/sns/login`` *(inferred)*
* ``middle/account/sns/unbind`` *(inferred)*
* ``middle/gift/backpack/panel`` *(inferred)*
* ``middle/gift/backpack/trade/v2`` *(inferred)*
* ``middle/gift/list`` *(inferred)*
* ``middle/gift/panel/list`` *(inferred)*
* ``middle/gift/user/present`` *(inferred)*
* ``middle/im/token-and-chatroom-addr/get`` *(inferred)*

radio (10)
----------

* ``radio/sport/calculate``
* ``radio/sport/get`` — ``bpm``
* ``radio/sport/like`` — ``songId``, ``like``, ``alg``, ``time``, ``sbpm``, ``rbpm``
* ``radio/sport/offline/song/get`` — ``max``, ``song``
* ``radio/sport/skip`` — ``songId``, ``alg``, ``time``, ``sbpm``, ``rbpm``
* ``radio/sport/trash/add`` — ``songId``, ``alg``, ``time``, ``sbpm``, ``rbpm``
* ``v1/radio/get``
* ``v1/radio/like`` — ``trackId``, ``time``, ``alg``, ``like``, ``rqRefer``, ``songRqRefer``, ``mode``, ``subMode``, ``source``, ``checkToken``, ``userActionMap``
* ``v1/radio/skip`` — ``songId``, ``time``, ``alg``, ``mode``, ``subMode``, ``source``
* ``v1/radio/trash/add`` — ``songId``, ``time``, ``alg``, ``mode``, ``subMode``, ``source``

activity (9)
------------

* ``activity/airborne/book``
* ``activity/attract/artist/song/listened``
* ``activity/attract/fm/song/listened``
* ``activity/attract/user/redpackage`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``
* ``activity/detail`` — ``activityId``
* ``activity/easy/interaction/vote``
* ``activity/easy/interaction/vote/cancel``
* ``activity/easy/interaction/vote/list``
* ``activity/room/exit`` — ``activityRoomId``

reward (9)
----------

* ``reward/dj/toplist/get`` — ``type``, ``limit``, ``offset``
* ``reward/djprogram/rewardinfo`` — ``programid``
* ``reward/gift/get`` — ``rewardId``, ``artistId``, ``artistType``
* ``reward/item/get`` — ``id``, ``type``
* ``reward/item/rank`` — ``id``
* ``reward/resource/toplist`` — ``type``, ``all``, ``limit``, ``offset``
* ``reward/yunbei/add``
* ``reward/yunbei/layer/get``
* ``reward/yunbei/resource/info/get``

act (8)
-------

* ``act/all/event/feed/info`` — ``eventId``, ``eventUserId``, ``tabType``, ``rightTabType``, ``lasttime``, ``cursor``
* ``act/all/v1``
* ``act/detail/info``
* ``act/event/new`` — ``actid``, ``lasttime``
* ``act/event/reject`` — ``eventid``, ``actid``, ``eventId``, ``artistId``, ``userid``, ``id``, ``reason``, ``type``
* ``act/point/event/feed/get`` — ``actId``, ``pointId``
* ``act/topic/rcmd/note-topic/get`` *(inferred)*
* ``act/topic/rcmd/part`` — ``sceneId``

report (8)
----------

* ``report/msg/user`` — ``userid``, ``reason``, ``reportType``
* ``report/reportcomment`` — ``threadId``, ``commentId``, ``combindId``, ``type``, ``reason``, ``reportType``
* ``report/reportevent`` — ``id``, ``userid``, ``reason``, ``reportType``
* ``report/reportmlog`` — ``id``, ``reason``, ``reportType``
* ``report/reportmsg`` — ``userid``, ``reason``, ``reportType``, ``msgId``
* ``report/reportresource`` — ``resourceType``, ``resourceId``, ``reason``, ``reportType``
* ``report/reportuser`` — ``userid``, ``reason``, ``reportType``
* ``report/type/get``

msg (7)
-------

* ``msg/count/clear``
* ``msg/notice/delete`` — ``id``
* ``msg/private/noticeaccount/history``
* ``msg/private/send`` — ``id``, ``type``, ``userIds``, ``msg``, ``threadId``, ``sharedId``, ``picinfo``, ``generalInfo``, ``time``, ``checkToken``
* ``msg/private/service/lastmsg/update``
* ``msg/private/video/realtime/info/get``
* ``msg/recentcontact/get``

nuser (7)
---------

* ``nuser/baby/info/add``
* ``nuser/baby/info/get``
* ``nuser/baby/info/update``
* ``nuser/follow/users/simple/get``
* ``nuser/oauth2/sdk/appinfo/get`` — ``appId``, ``scope``, ``client``
* ``nuser/oauth2/sdk/authorize`` — ``appid``, ``pkg``, ``client``
* ``nuser/whitelist/desc/get`` — ``userId``, ``user_id``, ``reminder``, ``userid``

social (7)
----------

* ``social/category/list`` *(inferred)*
* ``social/category/scene/material/list`` *(inferred)*
* ``social/circle/bff/detail/fansgroup/activity``
* ``social/emoji/groups``
* ``social/emoji/groups/detail/page``
* ``social/event/bff/ad/resources`` — ``adextjson``, ``extPageParam``, ``lasttime``, ``pagesize``, ``rcmdtopic``, ``rcmduser``, ``netstate``, ``resolution``, ``needUrl``, ``pagenum``, ``type``, ``eventId``, ``eventUserId``, ``curr_impressed_ids``, ``algLogInfo``, ``redEventId``, ``adExtJson``, ``pageNumber``, ``pageSize``, ``scene``, ``time``
* ``social/user/status/reply/notice``

circle (6)
----------

* ``circle/demo/list``
* ``circle/demo/timeline``
* ``circle/entrance/artist/get`` — ``userId``
* ``circle/follow/status/get`` — ``circleId``
* ``circle/get`` — ``circleId``
* ``circle/my/circle``

cloudvideo (6)
--------------

* ``cloudvideo/category/list``
* ``cloudvideo/playurl`` — ``resolution``, ``ids``
* ``cloudvideo/v1/video/detail`` — ``id``
* ``cloudvideo/video/sub`` — ``id``, ``checkToken``
* ``cloudvideo/video/tag/list``
* ``cloudvideo/video/unsub`` — ``id``, ``checkToken``

mine (6)
--------

* ``mine/applet/redpoint``
* ``mine/applet/redpoint/click``
* ``mine/collect/header/info``
* ``mine/page/prompt/get``
* ``mine/page/tab/nums/count``
* ``mine/user/latest/resource/report``

socialsquare (6)
----------------

* ``socialsquare/banner/get``
* ``socialsquare/channels/get``
* ``socialsquare/chosen/video/get``
* ``socialsquare/get``
* ``socialsquare/v1/get``
* ``socialsquare/v2/get``

sp (6)
------

* ``sp/flow/addr/v2``
* ``sp/flow/card/log/upload``
* ``sp/flow/popup/query``
* ``sp/flow/status/v2``
* ``sp/flow/usage/notify``
* ``sp/flow/user/status``

djprogram (5)
-------------

* ``djprogram/agreement/status``
* ``djprogram/babyfm/get``
* ``djprogram/delete`` — ``id``
* ``djprogram/v2/add/mobile``
* ``djprogram/v2/edit/mobile`` — ``id``, ``name``, ``desc``, ``cover``, ``radioId``, ``secondCategoryId``, ``isPrivate``, ``privacy``, ``publishTime``

mv (5)
------

* ``mv/all`` — ``limit``, ``offset``, ``tags``
* ``mv/exclusive/rcmd`` — ``limit``
* ``mv/first/allarea`` — ``limit``
* ``mv/tags`` — ``limit``, ``offset``, ``tags``
* ``v1/mv/detail`` — ``id``

personalized (5)
----------------

* ``personalized/block/feed/v2``
* ``personalized/block/old/v2``
* ``personalized/dislike/reason``
* ``personalized/mv`` — ``offset``, ``resolution``, ``needUrl``, ``groupId``, ``threadId``
* ``personalized/playlist/tag/rcmd``

play-record (5)
---------------

* ``play-record/album/list``
* ``play-record/djradio/list``
* ``play-record/newvideo/list``
* ``play-record/playlist/list``
* ``play-record/song/list``

setting (5)
-----------

* ``setting/developer``
* ``setting/floatpermission`` — ``transitionType``, ``crossFadeDuration``, ``playPlayListOnlyInWiFI``, ``donwloadPlayListOnlyInWiFI``, ``ignoreAudioFocus``, ``mlogDetailPlayIn4G``, ``inWifiAutoPlayVideo``, ``autoEnterFmMode``, ``bluetoothCarAutoPlay``, ``bluetoothAutoPlay``, ``statusLyricSwitch``, ``showFloatLyric``, ``floatLyricLock``, ``earphonesControl``, ``findMeThroughContact``, ``showOnlineStateToMyFollowFriends``, ``personalService``, ``showLiveRcmd``, ``allowOfflineNotify``, ``meizuStatusBarLyricSwitch``
* ``setting/lockscreenpermission`` — ``afterAppearOrpheus``, ``sourceTrialType``
* ``setting/user/module/tags``
* ``setting/widgetsetting``

story (5)
---------

* ``story/page/bottom/pic/get`` *(inferred)*
* ``story/page/lyric/to/voice/get`` *(inferred)*
* ``story/page/statement/get`` *(inferred)*
* ``story/page/topic/list`` *(inferred)*
* ``story/page/tts/show`` *(inferred)*

sub (5)
-------

* ``sub/artist/new/works/mv/list`` — ``startTimestamp``, ``limit``
* ``sub/artist/new/works/song/list`` — ``startTimestamp``, ``limit``
* ``sub/artist/new/works/song/playall``
* ``sub/artist/publish/switch``
* ``sub/artist/publish/switch/get`` — ``artistUserId``, ``artistId``

vip (5)
-------

* ``vip/cashier/nonts/get`` — ``songId``, ``count``, ``soundQuality``, ``download``, ``width``, ``height``, ``density``, ``tipStatus``, ``group``
* ``vip/cashier/tspopup/get``
* ``vip/config/url``
* ``vip/newuser/give/submit``
* ``vip/yi/dong/push/info/get`` *(inferred)*

baby (4)
--------

* ``baby/banner/get``
* ``baby/block/feed``
* ``baby/fm/config``
* ``baby/fm/get``

largeshow (4)
-------------

* ``largeshow/follow`` *(inferred)*
* ``largeshow/room/dynamic`` *(inferred)*
* ``largeshow/room/get`` *(inferred)*
* ``largeshow/room/leave`` *(inferred)*

quality (4)
-----------

* ``quality/resource/grade/add``
* ``quality/resource/grade/close``
* ``quality/resource/grade/get``
* ``quality/resource/grade/open``

alarm (3)
---------

* ``alarm/audition/url`` — ``id``
* ``alarm/get``
* ``alarm/song/url`` — ``id``

college (3)
-----------

* ``college/search/around`` — ``lon``, ``lat``
* ``college/user/update``
* ``college/usercollege/get`` — ``userId``

delivery (3)
------------

* ``delivery/batch-deliver``
* ``delivery/deliver``
* ``delivery/popup`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

feedback (3)
------------

* ``feedback``
* ``feedback/log/android``
* ``v1/feedback/lyric`` — ``errorType``, ``lyricVersion``, ``songId``, ``xInfo``

lyricvideo (3)
--------------

* ``lyricvideo/v1/effect/get``
* ``lyricvideo/v1/filter/get``
* ``lyricvideo/v1/resource/list/get``

mix (3)
-------

* ``mix/config/android``
* ``mix/container`` — ``noteHomeType``, ``homeReqSource``, ``homeFrameworkType``, ``pageCode``
* ``mix/orpheus/convert`` — ``url``

nearby (3)
----------

* ``nearby/banners`` — ``lat``, ``lon``, ``limit``, ``distance``, ``offset``, ``key``, ``c``
* ``nearby/banners/v1`` — ``historyIds``, ``teenage``
* ``nearby/campusstar/get`` — ``lat``, ``lon``, ``limit``, ``distance``, ``offset``, ``key``, ``c``

pendant (3)
-----------

* ``pendant/app/newonline``
* ``pendant/bubble/judge``
* ``pendant/user/get`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

podcast (3)
-----------

* ``podcast/playback/speed/get`` *(inferred)*
* ``podcast/playback/speed/set`` *(inferred)*
* ``podcast/user/interest/label/save``

resniche (3)
------------

* ``resniche/commontext/batch/get``
* ``resniche/guiderule/get``
* ``resniche/position/play/new/get`` — ``songId``, ``count``, ``soundQuality``, ``download``, ``width``, ``height``, ``density``, ``tipStatus``, ``group``

resource-exposure (3)
---------------------

* ``resource-exposure/config`` — ``userId``
* ``resource-exposure/configs``
* ``resource-exposure/pop-up/window/config/get`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

socialmix (3)
-------------

* ``socialmix/dailyrecommend/topally/get``
* ``socialmix/songchoose/info``
* ``socialmix/songchoose/m/config``

symphony (3)
------------

* ``symphony/chatroom/info/get``
* ``symphony/chatroom/msg/getstick``
* ``symphony/promotion/module``

toplist (3)
-----------

* ``toplist/artist`` — ``type``
* ``toplist/default/pics/v2``
* ``toplist/detail/v2``

videotimeline (3)
-----------------

* ``videotimeline/get``
* ``videotimeline/videogroup/get`` — ``offset``, ``resolution``, ``needUrl``, ``groupId``, ``threadId``
* ``videotimeline/videogroup/get-`` — ``offset``, ``resolution``, ``needUrl``, ``groupId``, ``threadId``

vipmall (3)
-----------

* ``vipmall/albumproduct/baseinfo``
* ``vipmall/albumproduct/sales``
* ``vipmall/couponcfg/get`` — ``historyIds``, ``teenage``

vipnewcenter (3)
----------------

* ``vipnewcenter/app/hepai/recommend/getList`` *(inferred)*
* ``vipnewcenter/app/resource/newaccountpage``
* ``vipnewcenter/app/vip/logo`` *(inferred)*

w (3)
-----

* ``w/activate/initProfile``
* ``w/login``
* ``w/login/cellphone``

aio (2)
-------

* ``aio/produce/material/batch/get``
* ``aio/produce/material/group/get``

android (2)
-----------

* ``android/version``
* ``android/version/graytest`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

concert (2)
-----------

* ``concert/artist/sharing`` — ``artId``
* ``concert/list/artconcerts`` — ``artistId``, ``offset``

fans (2)
--------

* ``fans/group/symphony/channel/managers``
* ``fans/group/user/level/rights`` *(inferred)*

light (2)
---------

* ``light/voice/card/list`` *(inferred)*
* ``light/voice/duration/config`` *(inferred)*

link (2)
--------

* ``link/position/show/feedback`` *(inferred)*
* ``link/position/show/resource`` — ``fee``, ``flag``, ``playMaxbr``, ``vip_type``, ``songPrivilege``, ``positionCode``, ``extJson``, ``type``, ``vipLimitFreeTimestamp``, ``vipActivity``, ``resourceId``

live (2)
--------

* ``live/rtc/pos/inner/res/user/upload`` *(inferred)*
* ``live/rtc/pos/manager/on`` *(inferred)*

log (2)
-------

* ``log``
* ``v1/log``

lunacache (2)
-------------

* ``lunacache/resinfo/get``
* ``lunacache/reslist``

magent (2)
----------

* ``magent/chat/send/async`` *(inferred)*
* ``magent/tool/execute/callback`` *(inferred)*

matcher (2)
-----------

* ``matcher/audio/algorithm-code/get``
* ``matcher/audio/multi/algorithm-configuration/get``

music-vip-open (2)
------------------

* ``music-vip-open/partner/cmcc/package/subscript`` *(inferred)*
* ``music-vip-open/partner/cmcc/package/update/content`` *(inferred)*

music-vip-thoth (2)
-------------------

* ``music-vip-thoth/front/yidong/activity/report`` *(inferred)*
* ``music-vip-thoth/front/yidong/can-call`` *(inferred)*

newuser (2)
-----------

* ``newuser/download/toast/get``
* ``newuser/songplay/toast/get``

nickname (2)
------------

* ``nickname/duplicated``
* ``nickname/hint/get`` — ``nickname``

popularmusic (2)
----------------

* ``v1/popularmusic/nearby`` — ``lat``, ``lon``, ``limit``, ``distance``, ``offset``, ``key``, ``c``
* ``v2/popularmusic/nearby`` — ``lat``, ``lon``, ``distance``, ``limit``, ``offset``, ``key``, ``c``

register (2)
------------

* ``register/anonimous`` — ``username``
* ``register/cellphone``

rncache (2)
-----------

* ``rncache/resinfo/get/cdn``
* ``rncache/reslist/cdn``

share (2)
---------

* ``share/encourage/config``
* ``share/friends/resource`` — ``type``, ``id``, ``eventId``, ``title``, ``msg``, ``threadId``, ``uuid``, ``actId``, ``pics``, ``soundeffectsType``, ``soundeffectsId``, ``soundeffectsFeed``, ``privacySetting``, ``anonymous``, ``addComment``, ``lotteryId``, ``checkToken``, ``webviewTitle``, ``webviewSubTitle``, ``webviewRedTag``, ``webviewCoverImgUrl``, ``webviewUrl``, ``orpheusUrl``, ``extId``, ``extType``, ``circleId``, ``audioExt``, ``targetPublishTime``, ``pointTopicInfo``, ``invalidActivityName``, ``activityInfoList``, ``distributionType``, ``extSource``, ``location``, ``socialUserId``, ``socialSpaceVisible``, ``redEnvelopeInfo``, ``pubSource``

sms (2)
-------

* ``sms/captcha/sent``
* ``sms/captcha/verify``

theme (2)
---------

* ``theme/get/categories``
* ``theme/get/v3``

upload (2)
----------

* ``upload/cloud/info/v2``
* ``upload/event/img/v1``

vip-rights (2)
--------------

* ``vip-rights/emotion/audio/effect/get`` *(inferred)*
* ``vip-rights/svip/sound/effect/get`` *(inferred)*

yunbei (2)
----------

* ``yunbei/account/entrance/get`` — ``historyIds``, ``teenage``
* ``yunbei/rcmd/song/get``

%s (1)
------

* ``v2/%s/%s%s``

about (1)
---------

* ``about/config``

activate (1)
------------

* ``activate/initProfile``

activitycenter (1)
------------------

* ``activitycenter/promotion/product/querybytype``

appcustomconfig (1)
-------------------

* ``appcustomconfig/get``

auth (1)
--------

* ``auth/artist`` — ``resourceid``, ``type``, ``threadId``, ``checkSyncEvent``, ``source``, ``voiceExposure``

autopay (1)
-----------

* ``autopay/sign/query``

banner (1)
----------

* ``banner/get/v3``

batch (1)
---------

* ``batch`` — ``step``, ``url``, ``sceneID``, ``reason``

block (1)
---------

* ``block/personal/base/info/identity/get``

cart (1)
--------

* ``cart/recommend``

cdns (1)
--------

* ``cdns``

cellphone (1)
-------------

* ``cellphone/existence/check``

communication (1)
-----------------

* ``communication/artist/trend/show``

community (1)
-------------

* ``community/artist/home/listActionPoints`` — ``userId``

coop (1)
--------

* ``coop/xiaoice/voice/talk``

creator (1)
-----------

* ``creator/musician/reminder/message/get`` — ``historyIds``, ``teenage``

deviceinfo (1)
--------------

* ``deviceinfo/center/model/query``

douyin (1)
----------

* ``douyin/v1/client_event/upload_event``

file (1)
--------

* ``file/upload``

flow (1)
--------

* ``flow/ad/exposure/deeplink/get``

getconfig (1)
-------------

* ``v1/getconfig``

ichat (1)
---------

* ``ichat/chatbot/message/send`` *(inferred)*

lt (1)
------

* ``lt/playpage/guide``

mgrhome (1)
-----------

* ``mgrhome/banner/get`` — ``moduleName``

music-vip-membership (1)
------------------------

* ``music-vip-membership/client/vip/info`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

music-vip-rights (1)
--------------------

* ``music-vip-rights/relationship/info`` *(inferred)*

my (1)
------

* ``my/podcast/tab/recommend`` *(inferred)*

order (1)
---------

* ``order/create_and_pay/rmb`` — ``goodId``, ``goodSKUId``, ``goodSnapshootId``, ``payMethod``, ``from``, ``clientSign``, ``clientType``, ``address``, ``hidden``

page (1)
--------

* ``v1/page/head/detail``

password (1)
------------

* ``password/url/decode/get``

personal (1)
------------

* ``personal/home/page/tabs`` — ``userId``

pl (1)
------

* ``pl/count`` — ``backend``

play (1)
--------

* ``v1/play/record`` — ``uid``

playmode (1)
------------

* ``playmode/intelligence/list``

point (1)
---------

* ``point/retrieve`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

privacy (1)
-----------

* ``privacy/info/get/v2`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

privilege (1)
-------------

* ``privilege/song/charge/info``

purchased (1)
-------------

* ``purchased/vipexpire/popup/v2/save`` — ``type``, ``vipCode``

sdk (1)
-------

* ``sdk/channelinfo/query/orphues``

side-bar (1)
------------

* ``side-bar/mini-program/music-service/account`` — ``historyIds``, ``teenage``, ``popUpStat``, ``userPopUpStat``

similar (1)
-----------

* ``v1/similar/artist/get``

spider (1)
----------

* ``spider``

springtone (1)
--------------

* ``springtone/exist``

stoplivechallenge (1)
---------------------

* ``stoplivechallenge/component`` *(inferred)*

subcount (1)
------------

* ``subcount/all``

throughtrain (1)
----------------

* ``v3/throughtrain/list``

usersafe (1)
------------

* ``usersafe/loginprotect/text/get``

vip-auth (1)
------------

* ``vip-auth/diy/sound/song/param`` *(inferred)*

vipmusic (1)
------------

* ``vipmusic/newrecord/entrance``

voicelist (1)
-------------

* ``voicelist/all/category/get`` *(inferred)*

webcache (1)
------------

* ``webcache/reslist/v2`` — ``platform``

zone (1)
--------

* ``zone/songplay/entry/get``

