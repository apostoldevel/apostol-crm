/*++

Program name:

  aws

Module Name:

  aws.hpp

Notices:

  Apostol Web Service

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_APOSTOL_HPP
#define APOSTOL_APOSTOL_HPP
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

    namespace AWS {

        class CAWS: public CApplication {
        protected:

            void ParseCmdLine() override;
            void ShowVersionInfo() override;

            void StartProcess() override;

        public:

            CAWS(int argc, char *const *argv): CApplication(argc, argv) {

            };

            ~CAWS() override = default;

            static class CAWS *Create(int argc, char *const *argv) {
                return new CAWS(argc, argv);
            };

            inline void Destroy() override { delete this; };

            void Run() override;

        };
    }
}

using namespace Apostol::AWS;
}

#endif //APOSTOL_APOSTOL_HPP

