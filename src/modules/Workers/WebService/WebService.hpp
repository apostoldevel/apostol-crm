/*++

Program name:

  Apostol Web Service

Module Name:

  WebService.hpp

Notices:

  Module WebService 

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_WEBSERVICE_HPP
#define APOSTOL_WEBSERVICE_HPP
//----------------------------------------------------------------------------------------------------------------------

extern "C++" {

namespace Apostol {

    namespace Workers {

        //--------------------------------------------------------------------------------------------------------------

        //-- CWebService -----------------------------------------------------------------------------------------------

        //--------------------------------------------------------------------------------------------------------------

        class CWebService: public CApostolModule {
        private:

            CString m_Password;

            CDateTime m_FixedDate;

            CSessionManager m_SessionManager;

            void InitMethods() override;

            static void AfterQueryWS(CHTTPServerConnection *AConnection, const CString &Path, const CJSON &Payload);
            static void AfterQuery(CHTTPServerConnection *AConnection, const CString &Path, const CJSON &Payload);

            void QueryException(CPQPollQuery *APollQuery, const std::exception &e);

            void LoadProviders();

            static bool CheckAuthorizationData(CRequest *ARequest, CAuthorization &Authorization);

            CString CreateToken(const CCleanToken& CleanToken);
            CString VerifyToken(const CString &Token);

            static void ParseString(const CString &String, const CStringList &Strings, CStringList &Valid, CStringList &Invalid);

            static int CheckError(const CJSON &Json, CString &ErrorMessage, bool RaiseIfError = false);
            static int CheckOAuth2Error(const CJSON &Json, CString &Error, CString &ErrorDescription);
            static CReply::CStatusType ErrorCodeToStatus(int ErrorCode);

            static void RedirectError(CHTTPServerConnection *AConnection, const CString &Location, int ErrorCode, const CString &Error, const CString &Message);
            static void ReplyError(CHTTPServerConnection *AConnection, CReply::CStatusType ErrorCode, const CString &Message);
            static void OAuth2Error(CHTTPServerConnection *AConnection, int ErrorCode, const CString &Error, const CString &Message);

            static void SetAuthorizationData(CHTTPServerConnection *AConnection, const CJSON &Payload);
            void SignInToken(CHTTPServerConnection *AConnection, const CJSON &Token);

        protected:

            void DoFetch(CHTTPServerConnection *AConnection, const CString& Path);

            void DoSessionDisconnected(CObject *Sender);

            void DoAPI(CHTTPServerConnection *AConnection);

            void DoWSSession(CHTTPServerConnection *AConnection);
            void DoWebSocket(CHTTPServerConnection *AConnection);

            void DoAuthorize(CHTTPServerConnection *AConnection);
            void DoOAuth2(CHTTPServerConnection *AConnection);
            void DoToken(CHTTPServerConnection *AConnection);

            void DoGet(CHTTPServerConnection *AConnection) override;
            void DoPost(CHTTPServerConnection *AConnection);

            void DoPostgresQueryExecuted(CPQPollQuery *APollQuery) override;
            void DoPostgresQueryException(CPQPollQuery *APollQuery, Delphi::Exception::Exception *AException) override;

        public:

            explicit CWebService(CModuleProcess *AProcess);

            ~CWebService() override = default;

            static class CWebService *CreateModule(CModuleProcess *AProcess) {
                return new CWebService(AProcess);
            }

            void Initialization(CModuleProcess *AProcess) override;

            void Heartbeat() override;
            void Execute(CHTTPServerConnection *AConnection) override;

            bool IsEnabled() override;
            bool CheckUserAgent(const CString& Value) override;

            void Authorize(CHTTPServerConnection *AConnection, const CString &Session, const CString &Path, const CString &Resource);

            void Identifier(CHTTPServerConnection *AConnection, const CString &Identifier);

            void UnauthorizedFetch(CHTTPServerConnection *AConnection, const CString &Path, const CString &Payload,
                    const CString &Agent, const CString &Host);

            void AuthorizedFetch(CHTTPServerConnection *AConnection, const CAuthorization &Authorization,
                           const CString &Path, const CString &Payload, const CString &Agent, const CString &Host);

            void SignedFetch(CHTTPServerConnection *AConnection, const CString &Path, const CString &Payload,
                             const CString &Session, const CString &Nonce, const CString &Signature, const CString &Agent,
                             const CString &Host, long int ReceiveWindow = 5000);

            static CString GetSession(CRequest *ARequest);
            static bool CheckSession(CRequest *ARequest, CString &Session);

            bool CheckAuthorization(CHTTPServerConnection *AConnection, CAuthorization &Authorization);

            static int NeedAuthorization(const CString &Path, const CString &Ext);

        };
    }
}

using namespace Apostol::Workers;
}
#endif //APOSTOL_WEBSERVICE_HPP
