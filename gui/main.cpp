// SparkMusic — STILLE desktop shell.
//
// Creates the Qt Quick engine, hands the Rust `SparkMusicClient` QObject to QML
// as the `core` context property, and optionally renders one frame to a PNG
// (`--screenshot out.png`) so the UI can be checked headlessly.

#include <cstdio>

#include <QGuiApplication>
#include <QFontDatabase>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>
#include <QUrl>
#include <QImage>
#include <QStringList>
#include <QDebug>

#include "sparkmusic-core/src/lib.cxxqt.h"

int main(int argc, char *argv[])
{
    // Handle --version before creating the GUI application so it also works
    // on a headless machine without a display server.
    for (int i = 1; i < argc; ++i) {
        if (qstrcmp(argv[i], "--version") == 0 || qstrcmp(argv[i], "-v") == 0) {
            std::printf("sparkmusic %s\n", SPARKMUSIC_VERSION);
            return 0;
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationVersion(QStringLiteral(SPARKMUSIC_VERSION));
    app.setWindowIcon(QIcon(QStringLiteral(":/branding/icon-paper.png")));
    app.setOrganizationName(QStringLiteral("SparkMusic"));
    app.setApplicationName(QStringLiteral("STILLE"));

    // Cormorant Garamond (OFL): display-only Latin serif, bundled as a Latin
    // subset so no machine font is required. Small labels stay on Noto Serif.
    for (const char *font : {":/fonts/CormorantGaramond-Regular.ttf",
                             ":/fonts/CormorantGaramond-SemiBold.ttf"}) {
        if (QFontDatabase::addApplicationFont(QString::fromLatin1(font)) < 0)
            qWarning() << "could not load bundled font" << font;
    }

    QString screenshot;
    QString initialView = QStringLiteral("home");
    QString initialSection = QStringLiteral("curated");
    QString initialQuery;
    QString initialTheme = QStringLiteral("paper");
    int initialPlay = -1;
    int shotDelay = 2500;
    int loginAfter = -1;
    int nextAfter = -1;
    int sectionAfter = -1;
    QString sectionAfterName;
    int likedAfter = -1;
    QString loginMode;
    bool exportOnStart = false;
    bool demoAccount = false;
    bool showLogin = false;

    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        if (args[i] == QLatin1String("--screenshot") && i + 1 < args.size()) {
            screenshot = args[++i];
        } else if (args[i] == QLatin1String("--view") && i + 1 < args.size()) {
            initialView = args[++i];
        } else if (args[i] == QLatin1String("--section") && i + 1 < args.size()) {
            initialSection = args[++i];
        } else if (args[i] == QLatin1String("--query") && i + 1 < args.size()) {
            initialQuery = args[++i];
        } else if (args[i] == QLatin1String("--theme") && i + 1 < args.size()) {
            initialTheme = args[++i];
        } else if (args[i] == QLatin1String("--demo-account")) {
            demoAccount = true;
        } else if (args[i] == QLatin1String("--export")) {
            exportOnStart = true;
        } else if (args[i] == QLatin1String("--login-mode") && i + 1 < args.size()) {
            loginMode = args[++i];
        } else if (args[i] == QLatin1String("--login-after") && i + 1 < args.size()) {
            loginAfter = args[++i].toInt();
        } else if (args[i] == QLatin1String("--next-after") && i + 1 < args.size()) {
            nextAfter = args[++i].toInt();
        } else if (args[i] == QLatin1String("--section-after") && i + 2 < args.size()) {
            sectionAfter = args[++i].toInt();
            sectionAfterName = args[++i];
        } else if (args[i] == QLatin1String("--liked-after") && i + 1 < args.size()) {
            likedAfter = args[++i].toInt();
        } else if (args[i] == QLatin1String("--delay") && i + 1 < args.size()) {
            shotDelay = args[++i].toInt();
        } else if (args[i] == QLatin1String("--play") && i + 1 < args.size()) {
            initialPlay = args[++i].toInt();
        } else if (args[i] == QLatin1String("--login")) {
            showLogin = true;
        }
    }

    SparkMusicClient client;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("core"), &client);
    engine.rootContext()->setContextProperty(QStringLiteral("initialView"),
                                              showLogin ? QStringLiteral("login") : initialView);
    engine.rootContext()->setContextProperty(QStringLiteral("initialSection"), initialSection);
    engine.rootContext()->setContextProperty(QStringLiteral("launchQuery"), initialQuery);
    engine.rootContext()->setContextProperty(QStringLiteral("launchTheme"), initialTheme);
    engine.rootContext()->setContextProperty(QStringLiteral("launchPlay"), initialPlay);
    engine.rootContext()->setContextProperty(QStringLiteral("launchLoginMode"), loginMode);
    engine.rootContext()->setContextProperty(QStringLiteral("launchDemoAccount"), demoAccount);

    engine.load(QUrl(QStringLiteral("qrc:/SparkMusic/qml/Main.qml")));
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "failed to load qrc:/SparkMusic/qml/Main.qml";
        return 1;
    }

    if (exportOnStart) {
        QTimer::singleShot(1500, &app, [&client]() {
            const QString path = client.exportFavorites(QString());
            qInfo().noquote() << "m3u8:" << (path.isEmpty() ? QStringLiteral("<failed>") : path);
        });
    }

    if (loginAfter >= 0) {
        // Debug hook: exercise the home -> login transition (QR must refresh).
        QTimer::singleShot(loginAfter, &app, [&engine]() {
            if (!engine.rootObjects().isEmpty())
                engine.rootObjects().constFirst()->setProperty("view", QStringLiteral("login"));
        });
    }

    if (nextAfter >= 0) {
        // Debug hook: exercise the archival track transition headlessly.
        QTimer::singleShot(nextAfter, &app, [&engine]() {
            if (!engine.rootObjects().isEmpty())
                QMetaObject::invokeMethod(engine.rootObjects().constFirst(), "nextTrack");
        });
    }

    if (sectionAfter >= 0 && !sectionAfterName.isEmpty()) {
        // Debug hook: exercise the section tab transition headlessly.
        QTimer::singleShot(sectionAfter, &app, [&engine, sectionAfterName]() {
            if (!engine.rootObjects().isEmpty())
                engine.rootObjects().constFirst()->setProperty("section", sectionAfterName);
        });
    }

    if (likedAfter >= 0) {
        // Debug hook: load the account's liked playlist and show it.
        QTimer::singleShot(likedAfter, &app, [&engine]() {
            if (engine.rootObjects().isEmpty()) return;
            auto *root = engine.rootObjects().constFirst();
            QMetaObject::invokeMethod(root, "loadLiked");
            root->setProperty("section", QStringLiteral("curated"));
        });
    }

    if (!screenshot.isEmpty()) {
        // Give the engine a moment to lay out and run entrance animations.
        QTimer::singleShot(shotDelay, &app, [&engine, screenshot]() {
            auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
            if (!window) {
                qCritical() << "root object is not a window";
                QCoreApplication::exit(2);
                return;
            }
            const QImage image = window->grabWindow();
            if (!image.save(screenshot)) {
                qCritical() << "could not save screenshot to" << screenshot;
                QCoreApplication::exit(3);
                return;
            }
            qInfo() << "screenshot written:" << screenshot << image.size();
            QCoreApplication::quit();
        });
    }

    return app.exec();
}
