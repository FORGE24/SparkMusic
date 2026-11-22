// C entry points for the shared core library.
//
// Keeping construction and destruction inside the library makes the Windows
// DLL self-contained: the GUI never imports the CXX-Qt class, its vtable or its
// static metaobject, so no module-definition file or import annotations are
// needed.  See include/sparkmusic/core_api.h.

#include "sparkmusic/core_api.h"

#include "sparkmusic-core/src/lib.cxxqt.h"

QObject *sparkmusic_client_create(void)
{
    return new SparkMusicClient();
}

void sparkmusic_client_destroy(QObject *client)
{
    delete client;
}
