/*++

Program name:

  apostol-crm

Module Name:

  BaskEnd.hpp

Notices:

  Bask-End SQL.

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_BACKEND_HPP
#define APOSTOL_BACKEND_HPP

extern "C++" {

namespace Apostol {

    namespace BackEnd {

        namespace api {

            void login(CStringList &SQL, const CString &ClientId, const CString &ClientSecret, const CString &Agent, const CString &Host, const CString &Scope = {});
            void signin(CStringList &SQL, const CString &ClientId, const CString &ClientSecret, const CString &Agent, const CString &Host);
            void signout(CStringList &SQL, const CString &Session, bool close_all = false);
            void get_session(CStringList &SQL, const CString &Username, const CString &Agent, const CString &Host, const CString &Scope = {});
            void get_sessions(CStringList &SQL, const CString &Username, const CString &Agent, const CString &Host);
            void authorize(CStringList &SQL, const CString &Session);
            void su(CStringList &SQL, const CString &Username, const CString &Secret);
            void set_area(CStringList &SQL, const CString &Code = CString());
            void set_session_area(CStringList &SQL, const CString &Area);
            void set_object_label(CStringList &SQL, const CString &Id, const CString &Label);
            void get_object_file(CStringList &SQL, const CString &Id, const CString &Name, const CString &Path);

            void execute_object_action(CStringList &SQL, const CString &Id, const CString &Action);
            void execute_object_action_try(CStringList &SQL, const CString &Id, const CString &Action);

            void client(CStringList &SQL, const CString &Code);

            void job(CStringList &SQL, const CString &State);
            void inbox(CStringList &SQL, const CString &State);
            void outbox(CStringList &SQL, const CString &State);

            void set_message(CStringList &SQL, const CString &Id, const CString &Parent, const CString &Type,
                             const CString &Agent, const CString &Code, const CString &Profile,
                             const CString &Address, const CString &Subject, const CString &Content,
                             const CString &Label = CString(), const CString &Description = CString());

            void get_message(CStringList &SQL, const CString &Id);
            void get_service_message(CStringList &SQL, const CString &Id);

            void add_inbox(CStringList &SQL, const CString &Parent, const CString &Agent, const CString &Code,
                           const CString &Profile, const CString &Address, const CString &Subject,
                           const CString &Content,
                           const CString &Label = CString(), const CString &Description = CString());

            void add_outbox(CStringList &SQL, const CString &Parent, const CString &Agent, const CString &Code,
                            const CString &Profile, const CString &Address, const CString &Subject,
                            const CString &Content,
                            const CString &Label = CString(), const CString &Description = CString());

            void send_message(CStringList &SQL, const CString &Parent, const CString &Agent, const CString &Profile,
                              const CString &Address, const CString &Subject, const CString &Content,
                              const CString &Label = CString(), const CString &Description = CString());
        }
        //--------------------------------------------------------------------------------------------------------------
    }
}

using namespace Apostol::BackEnd;
}
#endif //APOSTOL_BACKEND_HPP
