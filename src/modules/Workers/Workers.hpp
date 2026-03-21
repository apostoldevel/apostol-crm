#pragma once

// ─── Workers.hpp ─────────────────────────────────────────────────────────────
//
// Registration header for all Worker modules (HTTP/WebSocket request handlers).
//
// create_workers() is called from Application::on_worker_start() in main.cpp.

#include "apostol/application.hpp"

#ifdef WITH_POSTGRESQL
#include "PGHTTP/PGHTTP.hpp"
#endif

#if defined(WITH_POSTGRESQL) && defined(WITH_SSL)
#include "AppServer/AppServer.hpp"
#include "AuthServer/AuthServer.hpp"
#include "FileServer/FileServer.hpp"
#include "WebSocketAPI/WebSocketAPI.hpp"
#endif

#include "WebServer/WebServer.hpp"

namespace apostol
{

/// Instantiate and register all Worker modules with the module manager.
static inline void create_workers(Application& app)
{
#if defined(WITH_POSTGRESQL) && defined(WITH_SSL)
    if (app.module_enabled("AuthServer") && app.has_db_pool())
        app.module_manager().add_module(std::make_unique<AuthServer>(app));

    if (app.module_enabled("AppServer") && app.has_db_pool())
        app.module_manager().add_module(std::make_unique<AppServer>(app));
#endif

#ifdef WITH_POSTGRESQL
    if (app.module_enabled("PGHTTP") && app.has_db_pool())
        app.module_manager().add_module(std::make_unique<PGHTTP>(app));
#endif

#if defined(WITH_POSTGRESQL) && defined(WITH_SSL)
    if (app.module_enabled("FileServer") && app.has_db_pool())
        app.module_manager().add_module(std::make_unique<FileServer>(app));

    // WebSocketAPI — WS handler installed after all modules registered
    WebSocketAPI* ws_api_raw = nullptr;
    if (app.module_enabled("WebSocketAPI") && app.has_db_pool()) {
        auto ws_api = std::make_unique<WebSocketAPI>(app);
        ws_api_raw = ws_api.get();
        app.module_manager().add_module(std::move(ws_api));
    }
    if (ws_api_raw) {
        app.set_ws_handler(
            [ws_api_raw](EventLoop& loop, WsConnection ws, const HttpRequest& req) {
                ws_api_raw->on_ws_upgrade(loop, std::move(ws), req);
            });
    }
#endif

    // WebServer — last in chain (fallback to static files)
    app.module_manager().add_module(std::make_unique<WebServer>(app));
}

} // namespace apostol
