#pragma once

#include <QObject>
#include <QString>
#include <functional>

#include "sparkmusic-core/src/lib.cxxqt.h"

// A thin, queued façade for the blocking Rust core. Every network operation
// runs on Qt's global thread pool and reports back on the GUI thread, so the
// QML thread never waits for TLS/HTTP.
class CoreAsync : public QObject {
    Q_OBJECT
public:
    explicit CoreAsync(SparkMusicClient *core, QObject *parent = nullptr);

    Q_INVOKABLE void loadPlaylist(int requestId, qint64 id, int limit, const QString &title);
    Q_INVOKABLE void search(int requestId, const QString &query, int limit);
    Q_INVOKABLE void loadSongUrl(qint64 id, const QString &level);
    Q_INVOKABLE void loadLyric(qint64 id);
    Q_INVOKABLE void loadSongDetail(qint64 id);
    Q_INVOKABLE void loadAccount();
    Q_INVOKABLE void loadUserPlaylists(qint64 uid);
    Q_INVOKABLE void loadQrKey();
    Q_INVOKABLE void pollQr(const QString &key);
    Q_INVOKABLE void sendSms(const QString &phone);
    Q_INVOKABLE void loginSms(const QString &phone, const QString &captcha);
    Q_INVOKABLE void loginCookie(const QString &cookie);

signals:
    void playlistReady(int requestId, const QString &title, const QString &json);
    void searchReady(int requestId, const QString &query, const QString &json);
    void songUrlReady(qint64 id, const QString &json);
    void lyricReady(qint64 id, const QString &json);
    void songDetailReady(qint64 id, const QString &json);
    void accountReady(const QString &json);
    void userPlaylistsReady(const QString &json);
    void qrKeyReady(const QString &json);
    void qrCheckReady(const QString &json);
    void smsReady(const QString &json);
    void loginReady(const QString &json);

private:
    void run(const std::function<QString()> &work, const std::function<void(const QString &)> &done);

    SparkMusicClient *m_core;
};
