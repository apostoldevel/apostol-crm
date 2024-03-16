/*++

Program name:

  crm

Module Name:

  crm.hpp

Notices:

  Apostol Web Service

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_APOSTOL_CRM_HPP
#define APOSTOL_APOSTOL_CRM_HPP
//----------------------------------------------------------------------------------------------------------------------

#include "../../version.h"
//----------------------------------------------------------------------------------------------------------------------

#define APP_VERSION      AUTO_VERSION
#define APP_VER          APP_NAME "/" APP_VERSION
//----------------------------------------------------------------------------------------------------------------------

#include "Header.hpp"
//----------------------------------------------------------------------------------------------------------------------

extern "C++" {

namespace Apostol {

    namespace CRM {

        class CApostolCRM: public CApplication {
        protected:

            void ParseCmdLine() override;
            void ShowVersionInfo() override;

            void StartProcess() override;
            void CreateCustomProcesses() override;

        public:

            CApostolCRM(int argc, char *const *argv): CApplication(argc, argv) {

            };

            ~CApostolCRM() override = default;

            static class CApostolCRM *Create(int argc, char *const *argv) {
                return new CApostolCRM(argc, argv);
            };

            inline void Destroy() override { delete this; };

            void Run() override;

        };
    }
}

using namespace Apostol::CRM;
}

#endif //APOSTOL_APOSTOL_CRM_HPP

