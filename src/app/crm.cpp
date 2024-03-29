/*++

Program name:

  crm

Module Name:

  crm.cpp

Notices:

  Apostol Web Service

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#include "crm.hpp"
//----------------------------------------------------------------------------------------------------------------------

#define exit_failure(msg) {                                 \
  if (GLog != nullptr)                                      \
    GLog->Error(APP_LOG_EMERG, 0, msg);                     \
  else                                                      \
    std::cerr << APP_NAME << ": " << (msg) << std::endl;    \
  exitcode = EXIT_FAILURE;                                  \
}
//----------------------------------------------------------------------------------------------------------------------

extern "C++" {

namespace Apostol {

    namespace CRM {

        void CApostolCRM::ShowVersionInfo() {

            std::cerr << APP_NAME " version: " APP_VERSION " (" APP_DESCRIPTION ")" LINEFEED << std::endl;

            if (Config()->Flags().show_help) {
                std::cerr << "Usage: " APP_NAME << " [-?hvVt] [-s signal] [-c filename]"
                             " [-p prefix] [-g directives]" LINEFEED
                             LINEFEED
                             "Options:" LINEFEED
                             "  -?,-h         : this help" LINEFEED
                             "  -v            : show version and exit" LINEFEED
                             "  -V            : show version and configure options then exit" LINEFEED
                             "  -t            : test configuration and exit" LINEFEED
                             "  -s signal     : send signal to a master process: stop, quit, reopen, reload" LINEFEED
                             #ifdef APP_PREFIX
                             "  -p prefix     : set prefix path (default: " APP_PREFIX ")" LINEFEED
                             #else
                             "  -p prefix     : set prefix path (default: NONE)" LINEFEED
                             #endif
                             "  -c filename   : set configuration file (default: " APP_CONF_FILE ")" LINEFEED
                             "  -g directives : set global directives out of configuration file" LINEFEED
                             "  -l locale     : set locale (default: " APP_DEFAULT_LOCALE ")" LINEFEED
                          << std::endl;
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CApostolCRM::ParseCmdLine() {

            LPCTSTR P;

            for (int i = 1; i < argc(); ++i) {

                P = argv()[i].c_str();

                if (*P++ != '-') {
                    throw Delphi::Exception::ExceptionFrm(_T("invalid option: \"%s\""), P);
                }

                while (*P) {

                    switch (*P++) {

                        case '?':
                        case 'h':
                            Config()->Flags().show_version = true;
                            Config()->Flags().show_help = true;
                            break;

                        case 'v':
                            Config()->Flags().show_version = true;
                            break;

                        case 'V':
                            Config()->Flags().show_version = true;
                            Config()->Flags().show_configure = true;
                            break;

                        case 't':
                            Config()->Flags().test_config = true;
                            break;

                        case 'p':
                            if (*P) {
                                Config()->Prefix(P);
                                goto next;
                            }

                            if (!argv()[++i].empty()) {
                                Config()->Prefix(argv()[i]);
                                goto next;
                            }

                            throw Delphi::Exception::Exception(_T("option \"-p\" requires directory name"));

                        case 'c':
                            if (*P) {
                                Config()->ConfFile(P);
                                goto next;
                            }

                            if (!argv()[++i].empty()) {
                                Config()->ConfFile(argv()[i]);
                                goto next;
                            }

                            throw Delphi::Exception::Exception(_T("option \"-c\" requires file name"));

                        case 'g':
                            if (*P) {
                                Config()->ConfParam(P);
                                goto next;
                            }

                            if (!argv()[++i].empty()) {
                                Config()->ConfParam(argv()[i]);
                                goto next;
                            }

                            throw Delphi::Exception::Exception(_T("option \"-g\" requires parameter"));

                        case 'w':
                            if (*P) {
                                Config()->Workers(StrToIntDef(P, 0));
                                goto next;
                            }

                            if (++i < argc() && !argv()[i].empty()) {
                                Config()->Workers(StrToIntDef(argv()[i].c_str(), 0));
                                goto next;
                            }

                            throw Delphi::Exception::Exception(_T("option \"-w\" requires parameter"));

                        case 's':
                            if (*P) {
                                Config()->Signal(P);
                            } else if (!argv()[++i].empty()) {
                                Config()->Signal(argv()[i]);
                            } else {
                                throw Delphi::Exception::Exception(_T("option \"-s\" requires parameter"));
                            }

                            if (   Config()->Signal() == "stop"
                                   || Config()->Signal() == "quit"
                                   || Config()->Signal() == "reopen"
                                   || Config()->Signal() == "reload")
                            {
                                ProcessType(ptSignaller);
                                goto next;
                            }

                            throw Delphi::Exception::ExceptionFrm(_T("invalid option: \"-s %s\""), Config()->Signal().c_str());

                        case 'l':
                            if (*P) {
                                Config()->Locale(P);
                                goto next;
                            }

                            if (!argv()[++i].empty()) {
                                Config()->Locale(argv()[i]);
                                goto next;
                            }

                            throw Delphi::Exception::Exception(_T("option \"-l\" requires locale"));

                        default:
                            throw Delphi::Exception::ExceptionFrm(_T("invalid option: \"%c\""), *(P - 1));
                    }
                }

                next:

                continue;
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CApostolCRM::CreateCustomProcesses() {
            if (Config()->IniFile().ReadBool("process/MessageServer", "enable", false)) {
                AddProcess<CMessageServer>();
                m_ProcessType = ptCustom;
            }

            if (Config()->IniFile().ReadBool("process/ReportServer", "enable", false)) {
                AddProcess<CReportProcess>();
                m_ProcessType = ptCustom;
            }

            if (Config()->IniFile().ReadBool("process/TaskScheduler", "enable", false)) {
                AddProcess<CTaskScheduler>();
                m_ProcessType = ptCustom;
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CApostolCRM::StartProcess() {
            if (Config()->Helper()) {
                m_ProcessType = ptHelper;
            }

            CApplication::StartProcess();
        }
        //--------------------------------------------------------------------------------------------------------------

        void CApostolCRM::Run() {
            CApplication::Run();
        }
        //--------------------------------------------------------------------------------------------------------------
    }
}
}
//----------------------------------------------------------------------------------------------------------------------

int main(int argc, char *argv[]) {

    int exitcode;

    DefaultLocale.SetLocale("en_US");

    CApostolCRM crm(argc, argv);
    
    try
    {
        crm.Name() = APP_NAME;
        crm.Description() = APP_DESCRIPTION;
        crm.Version() = APP_VERSION;
        crm.Title() = APP_VER;

        crm.Run();

        exitcode = crm.ExitCode();
    }
    catch (std::exception& e)
    {
        exit_failure(e.what());
    }
    catch (...)
    {
        exit_failure("Unknown error...");
    }

    return exitcode;
}
//----------------------------------------------------------------------------------------------------------------------
