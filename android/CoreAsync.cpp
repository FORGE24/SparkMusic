#include "CoreAsync.h"

#include <QFutureWatcher>
#include <QtConcurrent/QtConcurrent>

CoreAsync::CoreAsync(SparkMusicClient *core, QObject *parent)
    : QObject(parent), m_core(core)
{
}

void CoreAsync::run(const std::function<QString()> &work,
                    const std::function<void(const QString &)> &done)
{
    auto *watcher = new QFutureWatcher<QString>(this);
    connect(watcher, &QFutureWatcher<QString>::finished, this,
            [watcher, done]() {
                done(watcher->result());
                watcher->deleteLater();
            });
    watcher->setFuture(QtConcurrent::run(work));
}

void CoreAsync::loadPlaylist(int requestId, qint64 id, int limit, const QString &title)
{
    run([core = m_core, id, limit]() { return core->playlist(id, limit); },
        [this, requestId, title](const QString &json) { emit playlistReady(requestId, title, json); });
}

void CoreAsync::search(int requestId, const QString &query, int limit)
{
    run([core = m_core, query, limit]() { return core->searchSongs(query, limit, 0); },
        [this, requestId, query](const QString &json) { emit searchReady(requestId, query, json); });
}

void CoreAsync::loadSongUrl(qint64 id, const QString &level)
{
    run([core = m_core, id, level]() { return core->songUrl(QString::number(id), level); },
        [this, id](const QString &json) { emit songUrlReady(id, json); });
}

void CoreAsync::loadLyric(qint64 id)
{
    run([core = m_core, id]() { return core->lyric(id); },
        [this, id](const QString &json) { emit lyricReady(id, json); });
}

void CoreAsync::loadSongDetail(qint64 id)
{
    run([core = m_core, id]() { return core->songDetail(id); },
        [this, id](const QString &json) { emit songDetailReady(id, json); });
}

void CoreAsync::loadAccount()
{
    run([core = m_core]() { return core->account(); },
        [this](const QString &json) { emit accountReady(json); });
}

void CoreAsync::loadUserPlaylists(qint64 uid)
{
    run([core = m_core, uid]() { return core->userPlaylists(uid); },
        [this](const QString &json) { emit userPlaylistsReady(json); });
}

void CoreAsync::loadQrKey()
{
    run([core = m_core]() { return core->loginQrKey(); },
        [this](const QString &json) { emit qrKeyReady(json); });
}

void CoreAsync::pollQr(const QString &key)
{
    run([core = m_core, key]() { return core->loginQrCheck(key); },
        [this](const QString &json) { emit qrCheckReady(json); });
}

void CoreAsync::sendSms(const QString &phone)
{
    run([core = m_core, phone]() { return core->sendSmsCode(phone); },
        [this](const QString &json) { emit smsReady(json); });
}

void CoreAsync::loginSms(const QString &phone, const QString &captcha)
{
    run([core = m_core, phone, captcha]() {
        const QString payload = QStringLiteral("{\"phone\":\"%1\",\"countrycode\":\"86\",\"captcha\":\"%2\"}")
                                    .arg(phone, captcha);
        return core->callWithMode(QStringLiteral("login/cellphone"), payload,
                                  QStringLiteral("weapi"));
    }, [this](const QString &json) { emit loginReady(json); });
}

void CoreAsync::loginCookie(const QString &cookie)
{
    run([core = m_core, cookie]() {
        core->setCookie(cookie);
        return core->account();
    }, [this](const QString &json) { emit loginReady(json); });
}
