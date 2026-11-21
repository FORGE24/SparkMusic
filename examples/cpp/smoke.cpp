// Minimal C++ consumer: proves the cxx-qt bridge is usable from Qt code.
#include <QCoreApplication>
#include <QDebug>
#include <QString>

#include "sparkmusic-core/src/lib.cxxqt.h"

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);

    SparkMusicClient client;
    qInfo() << "appVersion:" << client.appVersion();
    qInfo() << "routes:" << client.routeCount() << "groups:" << client.groupCount();

    const QString info = client.routeInfo(QStringLiteral("song/detail"));
    qInfo().noquote() << "routeInfo:" << info.left(140);

    const QString search = client.searchSongs(QStringLiteral("海阔天空"), 2, 0);
    qInfo().noquote() << "search:" << search.left(220);

    return 0;
}
