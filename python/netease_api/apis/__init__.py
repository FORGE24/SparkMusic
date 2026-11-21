"""Resource-specific API mixins.

Every class here is mixed into :class:`netease_api.client.NeteaseClient`; they
can also be inspected standalone for their route metadata.  Method docstrings
name the recovered route each call uses.
"""
from __future__ import annotations

from .base import ApiMixin, RESOURCE_TYPES, THREAD_PREFIXES
from .cloud import CloudApi, VipApi
from .comment import CommentApi
from .dj import DjApi, RadioApi
from .login import LoginApi
from .misc import FeedbackApi, ListenTogetherApi, MineApi, ReportApi, SettingApi
from .music import AlbumApi, ArtistApi, MvApi, SongApi
from .playlist import PlaylistApi
from .recommend import PersonalizedApi, RecommendApi, ToplistApi
from .search import SEARCH_TYPES, SearchApi
from .social import EventApi, MlogApi, MsgApi, TopicApi
from .user import UserApi

#: Mixin classes in the order their methods become available on the client.
MIXINS = (
    LoginApi,
    UserApi,
    SongApi,
    AlbumApi,
    ArtistApi,
    MvApi,
    PlaylistApi,
    SearchApi,
    CommentApi,
    DjApi,
    RadioApi,
    RecommendApi,
    PersonalizedApi,
    ToplistApi,
    EventApi,
    MlogApi,
    TopicApi,
    MsgApi,
    CloudApi,
    VipApi,
    SettingApi,
    ReportApi,
    FeedbackApi,
    ListenTogetherApi,
    MineApi,
)

__all__ = [
    "ApiMixin",
    "RESOURCE_TYPES",
    "THREAD_PREFIXES",
    "MIXINS",
    "SEARCH_TYPES",
    "LoginApi",
    "UserApi",
    "SongApi",
    "AlbumApi",
    "ArtistApi",
    "MvApi",
    "PlaylistApi",
    "SearchApi",
    "CommentApi",
    "DjApi",
    "RadioApi",
    "RecommendApi",
    "PersonalizedApi",
    "ToplistApi",
    "EventApi",
    "MlogApi",
    "TopicApi",
    "MsgApi",
    "CloudApi",
    "VipApi",
    "SettingApi",
    "ReportApi",
    "FeedbackApi",
    "ListenTogetherApi",
    "MineApi",
]
