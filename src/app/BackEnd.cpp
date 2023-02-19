/*++

Program name:

  apostol-crm

Module Name:

  BaskEnd.cpp

Notices:

  Bask-End SQL.

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#include "Core.hpp"
#include "BackEnd.hpp"
//----------------------------------------------------------------------------------------------------------------------

extern "C++" {

namespace Apostol {

    namespace BackEnd {

        namespace api {

            void login(CStringList &SQL, const CString &ClientId, const CString &ClientSecret, const CString &Agent,
                       const CString &Host, const CString &Scope) {
                SQL.Add(CString().Format("SELECT * FROM api.login(%s, %s, %s, %s, %s);",
                                         PQQuoteLiteral(ClientId).c_str(),
                                         PQQuoteLiteral(ClientSecret).c_str(),
                                         PQQuoteLiteral(Agent).c_str(),
                                         PQQuoteLiteral(Host).c_str(),
                                         PQQuoteLiteral(Scope).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void signin(CStringList &SQL, const CString &ClientId, const CString &ClientSecret, const CString &Agent,
                       const CString &Host) {
                SQL.Add(CString().Format("SELECT * FROM api.signin(%s, %s, %s, %s);",
                                         PQQuoteLiteral(ClientId).c_str(),
                                         PQQuoteLiteral(ClientSecret).c_str(),
                                         PQQuoteLiteral(Agent).c_str(),
                                         PQQuoteLiteral(Host).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void signout(CStringList &SQL, const CString &Session, bool close_all) {
                SQL.Add(CString().Format("SELECT * FROM api.signout(%s, %s);",
                                         PQQuoteLiteral(Session).c_str(),
                                         close_all ? "true" : "false"
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void get_session(CStringList &SQL, const CString &Username, const CString &Agent, const CString &Host,
                             const CString &Scope) {
                SQL.Add(CString().Format("SELECT * FROM api.get_session(%s, %s, %s, %s);",
                                         PQQuoteLiteral(Username).c_str(),
                                         PQQuoteLiteral(Agent).c_str(),
                                         PQQuoteLiteral(Host).c_str(),
                                         PQQuoteLiteral(Scope).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void get_sessions(CStringList &SQL, const CString &Username, const CString &Agent, const CString &Host) {
                SQL.Add(CString().Format("SELECT * FROM api.get_sessions(%s, %s, %s);",
                                         PQQuoteLiteral(Username).c_str(),
                                         PQQuoteLiteral(Agent).c_str(),
                                         PQQuoteLiteral(Host).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void authorize(CStringList &SQL, const CString &Session) {
                SQL.Add(CString().Format("SELECT * FROM api.authorize(%s);",
                                         PQQuoteLiteral(Session).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void su(CStringList &SQL, const CString &Username, const CString &Secret) {
                SQL.Add(CString().Format("SELECT * FROM api.su(%s, %s);",
                                         PQQuoteLiteral(Username).c_str(),
                                         PQQuoteLiteral(Secret).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void set_area(CStringList &SQL, const CString &Code) {
                if (Code.IsEmpty()) {
                    SQL.Add("SELECT * FROM api.set_session_area(api.get_area_id(current_database()));");
                } else {
                    SQL.Add(CString().Format("SELECT * FROM api.set_session_area(api.get_area_id(%s));",
                                             PQQuoteLiteral(Code).c_str()
                    ));
                }
            }
            //----------------------------------------------------------------------------------------------------------

            void set_session_area(CStringList &SQL, const CString &Area) {
                SQL.Add(CString().Format("SELECT * FROM api.set_session_area(%s::uuid);",
                                         PQQuoteLiteral(Area).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void set_object_label(CStringList &SQL, const CString &Id, const CString &Label) {
                SQL.Add(CString().Format("SELECT * FROM api.set_object_label(%s::uuid, %s);",
                                         PQQuoteLiteral(Id).c_str(),
                                         PQQuoteLiteral(Label).c_str()
                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void get_object_file(CStringList &SQL, const CString &Id, const CString &Name, const CString &Path) {
                SQL.Add(CString().MaxFormatSize(256 + Id.Size() + Name.Size() + Path.Size())
                                .Format("SELECT * FROM api.get_object_file(%s, %s, %s)",
                                        PQQuoteLiteral(Id).c_str(),
                                        PQQuoteLiteral(Name).c_str(),
                                        PQQuoteLiteral(Path).c_str()
                                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void execute_object_action(CStringList &SQL, const CString &Id, const CString &Action) {
                SQL.Add(CString().Format("SELECT * FROM api.execute_object_action(%s::uuid, %s);",
                                         PQQuoteLiteral(Id).c_str(),
                                         PQQuoteLiteral(Action).c_str()
                ));

            }
            //----------------------------------------------------------------------------------------------------------

            void execute_object_action_try(CStringList &SQL, const CString &Id, const CString &Action) {
                SQL.Add(CString().Format("SELECT * FROM api.execute_object_action_try(%s::uuid, %s);",
                                         PQQuoteLiteral(Id).c_str(),
                                         PQQuoteLiteral(Action).c_str()
                ));

            }
            //----------------------------------------------------------------------------------------------------------

            void client(CStringList &SQL, const CString &Code) {
                SQL.Add(CString().Format("SELECT * FROM api.client(%s);", PQQuoteLiteral(Code).c_str()));
            }
            //----------------------------------------------------------------------------------------------------------

            void job(CStringList &SQL, const CString &State) {
                SQL.Add(CString().Format("SELECT * FROM api.job(%s) ORDER BY created;", PQQuoteLiteral(State).c_str()));
            }
            //----------------------------------------------------------------------------------------------------------

            void inbox(CStringList &SQL, const CString &State) {
                SQL.Add(CString().Format("SELECT * FROM api.inbox(%s) ORDER BY created;", PQQuoteLiteral(State).c_str()));
            }
            //----------------------------------------------------------------------------------------------------------

            void outbox(CStringList &SQL, const CString &State) {
                SQL.Add(CString().Format("SELECT * FROM api.outbox(%s) ORDER BY created;", PQQuoteLiteral(State).c_str()));
            }
            //----------------------------------------------------------------------------------------------------------

            void set_message(CStringList &SQL, const CString &Id, const CString &Parent, const CString &Type,
                             const CString &Agent, const CString &Code, const CString &Profile, const CString &Address,
                             const CString &Subject, const CString &Content, const CString &Label,
                             const CString &Description) {

                SQL.Add(CString()
                                .MaxFormatSize(256 + Id.Size() + Parent.Size() + Type.Size() + Agent.Size() + Code.Size() + Profile.Size() +
                                               Address.Size() + Subject.Size() + Content.Size() + Label.Size() + Description.Size())
                                .Format("SELECT * FROM api.set_message(%s, %s, api.get_type_id(%s), api.get_agent_id(%s), %s, %s, %s, %s, %s, %s, %s);",
                                        PQQuoteLiteral(Id).c_str(),
                                        PQQuoteLiteral(Parent).c_str(),
                                        PQQuoteLiteral(Type).c_str(),
                                        PQQuoteLiteral(Agent).c_str(),
                                        PQQuoteLiteral(Code).c_str(),
                                        PQQuoteLiteral(Profile).c_str(),
                                        PQQuoteLiteral(Address).c_str(),
                                        PQQuoteLiteral(Subject).c_str(),
                                        PQQuoteLiteral(Content).c_str(),
                                        PQQuoteLiteral(Label).c_str(),
                                        PQQuoteLiteral(Description).c_str()
                                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void get_message(CStringList &SQL, const CString &Id) {
                SQL.Add(CString().Format("SELECT * FROM api.get_message(%s);", PQQuoteLiteral(Id).c_str()));
            }
            //----------------------------------------------------------------------------------------------------------

            void get_service_message(CStringList &SQL, const CString &Id) {
                SQL.Add(CString().Format("SELECT * FROM api.get_service_message(%s);", PQQuoteLiteral(Id).c_str()));
            }
            //----------------------------------------------------------------------------------------------------------

            void add_inbox(CStringList &SQL, const CString &Parent, const CString &Agent, const CString &Code,
                           const CString &Profile, const CString &Address, const CString &Subject,
                           const CString &Content, const CString &Label, const CString &Description) {
                SQL.Add(CString()
                                .MaxFormatSize(256 + Parent.Size() + Agent.Size() + Code.Size() + Profile.Size() +
                                               Address.Size() + Subject.Size() + Content.Size() + Label.Size() + Description.Size())
                                .Format("SELECT * FROM api.add_inbox(%s, api.get_agent_id(%s), %s, %s, %s, %s, %s, %s, %s);",
                                        PQQuoteLiteral(Parent).c_str(),
                                        PQQuoteLiteral(Agent).c_str(),
                                        PQQuoteLiteral(Code).c_str(),
                                        PQQuoteLiteral(Profile).c_str(),
                                        PQQuoteLiteral(Address).c_str(),
                                        PQQuoteLiteral(Subject).c_str(),
                                        PQQuoteLiteral(Content).c_str(),
                                        PQQuoteLiteral(Label).c_str(),
                                        PQQuoteLiteral(Description).c_str()
                                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void add_outbox(CStringList &SQL, const CString &Parent, const CString &Agent, const CString &Code,
                            const CString &Profile, const CString &Address, const CString &Subject,
                            const CString &Content, const CString &Label, const CString &Description) {
                SQL.Add(CString()
                                .MaxFormatSize(256 + Parent.Size() + Agent.Size() + Code.Size() + Profile.Size() +
                                               Address.Size() + Subject.Size() + Content.Size() + Label.Size() + Description.Size())
                                .Format("SELECT * FROM api.add_outbox(%s, api.get_agent_id(%s), %s, %s, %s, %s, %s, %s, %s);",
                                        PQQuoteLiteral(Parent).c_str(),
                                        PQQuoteLiteral(Agent).c_str(),
                                        PQQuoteLiteral(Code).c_str(),
                                        PQQuoteLiteral(Profile).c_str(),
                                        PQQuoteLiteral(Address).c_str(),
                                        PQQuoteLiteral(Subject).c_str(),
                                        PQQuoteLiteral(Content).c_str(),
                                        PQQuoteLiteral(Label).c_str(),
                                        PQQuoteLiteral(Description).c_str()
                                ));
            }
            //----------------------------------------------------------------------------------------------------------

            void send_message(CStringList &SQL, const CString &Parent, const CString &Agent, const CString &Profile,
                              const CString &Address, const CString &Subject, const CString &Content,
                              const CString &Label, const CString &Description) {
                SQL.Add(CString()
                                .MaxFormatSize(256 + Parent.Size() + Agent.Size() + Profile.Size() + Address.Size() + Subject.Size() + Content.Size() + Label.Size() + Description.Size())
                                .Format("SELECT * FROM api.send_message(%s, api.get_agent_id(%s), %s, %s, %s, %s, %s, %s);",
                                        PQQuoteLiteral(Parent).c_str(),
                                        PQQuoteLiteral(Agent).c_str(),
                                        PQQuoteLiteral(Profile).c_str(),
                                        PQQuoteLiteral(Address).c_str(),
                                        PQQuoteLiteral(Subject).c_str(),
                                        PQQuoteLiteral(Content).c_str(),
                                        PQQuoteLiteral(Label).c_str(),
                                        PQQuoteLiteral(Description).c_str()
                                ));
            }
        }
    }
}
}