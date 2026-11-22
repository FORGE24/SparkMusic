#include <QDir>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QImage>
#include <QInputMethod>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QKeyEvent>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTimer>

#include "CoreAsync.h"
#include "sparkmusic-core/src/lib.cxxqt.h"

namespace {
class BackKeyFilter : public QObject {
public:
    BackKeyFilter(QObject *root, QObject *parent = nullptr) : QObject(parent), m_root(root) {}

    bool eventFilter(QObject *, QEvent *event) override
    {
        if (event->type() == QEvent::KeyPress) {
            auto *key = static_cast<QKeyEvent *>(event);
            if (key->key() == Qt::Key_Back) {
                // The first back press dismisses the soft keyboard; only the
                // next one navigates the paper stack.
                if (QGuiApplication::inputMethod() && QGuiApplication::inputMethod()->isVisible())
                    return false;
                QMetaObject::invokeMethod(m_root, "goBack");
                return true;
            }
        }
        return false;
    }

private:
    QObject *m_root;
};
} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("STILLE"));
    QGuiApplication::setOrganizationName(QStringLiteral("SparkMusic"));

    // The core persists favourites, history and the MUSIC_U session in one
    // SQLite file. Android has no HOME; point XDG_DATA_HOME at the app's
    // private files directory before constructing the client.
    const QString dataHome = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!dataHome.isEmpty()) {
        QDir().mkpath(dataHome);
        qputenv("XDG_DATA_HOME", dataHome.toUtf8());
    }

    // All-serif typography: Cormorant for Latin, Songti (Noto Serif SC) for
    // Chinese. The Chinese face is renamed STILLE Song at build time.
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/CormorantGaramond-Regular.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/CormorantGaramond-SemiBold.ttf"));
    QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/STILLE-Song.ttf"));

    SparkMusicClient client;
    CoreAsync api(&client);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("core"), &client);
    engine.rootContext()->setContextProperty(QStringLiteral("api"), &api);
    engine.loadFromModule("SparkMusicAndroid", "Main");
    if (engine.rootObjects().isEmpty())
        return -1;

    auto *root = engine.rootObjects().constFirst();
    if (auto *window = qobject_cast<QQuickWindow *>(root))
        window->installEventFilter(new BackKeyFilter(root, window));
    QString view;
    QString tab;
    QString theme;
    QString screenshot;
    bool queue = false;
    bool grid = false;
    bool playing = false;
    bool autoplay = false;
    bool clock = false;
    int viewAfter = -1;
    QString viewAfterName;
    bool openPlaylist = false;
    int delay = 1600;
    int playIndex = -1;
    QString expanded;
    QString query;
    QString loginMode;

    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        if (args[i] == QLatin1String("--view") && i + 1 < args.size()) view = args[++i];
        else if (args[i] == QLatin1String("--section") && i + 1 < args.size()) tab = args[++i];
        else if (args[i] == QLatin1String("--theme") && i + 1 < args.size()) theme = args[++i];
        else if (args[i] == QLatin1String("--screenshot") && i + 1 < args.size()) screenshot = args[++i];
        else if (args[i] == QLatin1String("--delay") && i + 1 < args.size()) delay = args[++i].toInt();
        else if (args[i] == QLatin1String("--play") && i + 1 < args.size()) playIndex = args[++i].toInt();
        else if (args[i] == QLatin1String("--queue")) queue = true;
        else if (args[i] == QLatin1String("--grid")) grid = true;
        else if (args[i] == QLatin1String("--playing")) playing = true;
        else if (args[i] == QLatin1String("--autoplay")) autoplay = true;
        else if (args[i] == QLatin1String("--clock")) clock = true;
        else if (args[i] == QLatin1String("--playlist")) openPlaylist = true;
        else if (args[i] == QLatin1String("--view-after") && i + 2 < args.size()) {
            viewAfter = args[++i].toInt();
            viewAfterName = args[++i];
        }
        else if (args[i] == QLatin1String("--expanded") && i + 1 < args.size()) expanded = args[++i];
        else if (args[i] == QLatin1String("--query") && i + 1 < args.size()) query = args[++i];
        else if (args[i] == QLatin1String("--login-mode") && i + 1 < args.size()) loginMode = args[++i];
    }

    if (!view.isEmpty()) root->setProperty("portraitView", view);
    if (!tab.isEmpty()) root->setProperty("homeTab", tab);
    if (!theme.isEmpty()) root->setProperty("themeMode", theme);
    if (playIndex >= 0) {
        root->setProperty("trackIndex", playIndex);
        root->setProperty("position", 24);
    }
    if (playing) root->setProperty("playing", true);
    if (autoplay) root->setProperty("autoPlayOnLoad", true);
    if (clock) root->setProperty("forceClockMode", true);
    if (viewAfter >= 0 && !viewAfterName.isEmpty()) {
        QTimer::singleShot(viewAfter, root, [root, viewAfterName]() {
            root->setProperty("portraitView", viewAfterName);
        });
    }
    if (openPlaylist) {
        QTimer::singleShot(4500, root, [root]() {
            QMetaObject::invokeMethod(root, "openPlaylist",
                                      Q_ARG(QVariant, QVariant::fromValue<qint64>(19723756)),
                                      Q_ARG(QVariant, QStringLiteral("飙升榜")),
                                      Q_ARG(QVariant, QStringLiteral("editions")));
        });
    }
    if (queue) root->setProperty("queueOpen", true);
    if (grid) root->setProperty("showGrid", true);
    if (!query.isEmpty()) root->setProperty("searchQuery", query);
    if (!expanded.isEmpty()) {
        QTimer::singleShot(3200, root, [root, expanded]() { root->setProperty("expandedTrackId", expanded); });
    }
    if (!loginMode.isEmpty()) {
        if (auto *login = root->findChild<QObject *>(QStringLiteral("loginView")))
            login->setProperty("mode", loginMode);
    }

    if (!screenshot.isEmpty()) {
        QTimer::singleShot(delay, &app, [&app, root, screenshot]() {
            if (auto *window = qobject_cast<QQuickWindow *>(root)) {
                const QImage image = window->grabWindow();
                image.save(screenshot);
                qInfo().noquote() << "screenshot written:" << screenshot << image.size();
            }
            app.quit();
        });
    }

    return app.exec();
}
