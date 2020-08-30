/*++

Program name:

  apostol

Module Name:

  Workers.hpp

Notices:

  Apostol Web Service

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_WORKERS_HPP
#define APOSTOL_WORKERS_HPP
//----------------------------------------------------------------------------------------------------------------------

#include "WebSocketAPI/WebSocketAPI.hpp"
#include "AppServer/AppServer.hpp"
#include "AuthServer/AuthServer.hpp"
#include "WebServer/WebServer.hpp"
//----------------------------------------------------------------------------------------------------------------------

static inline void CreateWorkers(CModuleProcess *AProcess) {
    CWebSocketAPI::CreateModule(AProcess);
    CAppServer::CreateModule(AProcess);
    CAuthServer::CreateModule(AProcess);
    CWebServer::CreateModule(AProcess);
}

#endif //APOSTOL_WORKERS_HPP
