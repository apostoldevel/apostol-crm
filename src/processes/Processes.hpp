/*++

Library name:

  apostol-core

Module Name:

  Processes.hpp

Notices:

  Application others processes

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_PROCESSES_HPP
#define APOSTOL_PROCESSES_HPP
//----------------------------------------------------------------------------------------------------------------------

#include "Header.hpp"
//----------------------------------------------------------------------------------------------------------------------

#include "MessageServer/MessageServer.hpp"
#include "ReportServer/ReportProcess.hpp"
#include "TaskScheduler/TaskScheduler.hpp"
//----------------------------------------------------------------------------------------------------------------------

static inline void CreateProcesses(CCustomProcess *AParent, CApplication *AApplication) {
    CMessageServer::CreateProcess(AParent, AApplication);
    CTaskScheduler::CreateProcess(AParent, AApplication);
    CReportProcess::CreateProcess(AParent, AApplication);
}

#endif //APOSTOL_PROCESSES_HPP
