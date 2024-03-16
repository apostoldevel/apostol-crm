/*++

Program name:

  Apostol CRM

Module Name:

  Helpers.hpp

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_HELPERS_HPP
#define APOSTOL_HELPERS_HPP
//----------------------------------------------------------------------------------------------------------------------

#include "PGFetch/PGFetch.hpp"
#include "PGFile/PGFile.hpp"

static inline void CreateHelpers(CModuleProcess *AProcess) {
    CPGFetch::CreateModule(AProcess);
    CPGFile::CreateModule(AProcess);
}

#endif //APOSTOL_HELPERS_HPP
