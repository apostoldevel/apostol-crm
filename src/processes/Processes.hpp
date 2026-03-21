#pragma once

// ─── Processes.hpp ───────────────────────────────────────────────────────────
//
// Central registration header for all background processes.
//
// create_processes() is called from create_custom_processes() in main.cpp.

#include "apostol/application.hpp"

#ifdef WITH_POSTGRESQL
#include "TaskScheduler/TaskScheduler.hpp"
#include "ReportServer/ReportServer.hpp"
#endif

#if defined(WITH_POSTGRESQL) && defined(WITH_SSL)
#include "MessageServer/MessageServer.hpp"
#endif

namespace apostol
{

/// Register all custom background processes with the Application.
static inline void create_processes(Application& app)
{
#ifdef WITH_POSTGRESQL
    if (app.module_enabled("TaskScheduler", false)
        && !app.settings().pg_conninfo_helper.empty())
        app.add_custom_process(std::make_unique<TaskScheduler>());

    if (app.module_enabled("ReportServer", false)
        && !app.settings().pg_conninfo_helper.empty())
        app.add_custom_process(std::make_unique<ReportServer>());
#endif

#if defined(WITH_POSTGRESQL) && defined(WITH_SSL)
    if (app.module_enabled("MessageServer", false)
        && !app.settings().pg_conninfo_helper.empty())
        app.add_custom_process(std::make_unique<MessageServer>());
#endif
    (void)app;
}

} // namespace apostol
