/*++

Program name:

  Apostol Web Service

Module Name:

  WebService.cpp

Notices:

  Module WebService

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

//----------------------------------------------------------------------------------------------------------------------

#include "Core.hpp"
#include "WebService.hpp"
//----------------------------------------------------------------------------------------------------------------------

#include "jwt.h"
//----------------------------------------------------------------------------------------------------------------------

#include <random>
#include <openssl/sha.h>
#include <openssl/hmac.h>
//----------------------------------------------------------------------------------------------------------------------

#define SHA256_DIGEST_LENGTH   32

extern "C++" {

namespace Apostol {

    namespace Workers {

        CString to_string(unsigned long Value) {
            TCHAR szString[_INT_T_LEN + 1] = {0};
            sprintf(szString, "%lu", Value);
            return CString(szString);
        }
        //--------------------------------------------------------------------------------------------------------------

        CString b2a_hex(const unsigned char *byte_arr, int size) {
            const static CString HexCodes = "0123456789abcdef";
            CString HexString;
            for ( int i = 0; i < size; ++i ) {
                unsigned char BinValue = byte_arr[i];
                HexString += HexCodes[(BinValue >> 4) & 0x0F];
                HexString += HexCodes[BinValue & 0x0F];
            }
            return HexString;
        }
        //--------------------------------------------------------------------------------------------------------------

        CString hmac_sha256(const CString &key, const CString &data) {
            unsigned char* digest;
            digest = HMAC(EVP_sha256(), key.data(), key.length(), (unsigned char *) data.data(), data.length(), nullptr, nullptr);
            return b2a_hex( digest, SHA256_DIGEST_LENGTH );
        }
        //--------------------------------------------------------------------------------------------------------------

        CString SHA1(const CString &data) {
            CString digest;
            digest.SetLength(SHA_DIGEST_LENGTH);
            ::SHA1((unsigned char *) data.data(), data.length(), (unsigned char *) digest.Data());
            return digest;
        }
        //--------------------------------------------------------------------------------------------------------------

        CDateTime StringToDate(const CString &Value) {
            return StrToDateTimeDef(Value.c_str(), 0, "%04d-%02d-%02d %02d:%02d:%02d");
        }
        //--------------------------------------------------------------------------------------------------------------

        CString DateToString(const CDateTime &Value) {
            TCHAR Buffer[20] = {0};
            DateTimeToStr(Value, Buffer, sizeof(Buffer));
            return Buffer;
        }
        //--------------------------------------------------------------------------------------------------------------

        CDateTime GetRandomDate(int a, int b, CDateTime Date) {
            std::random_device rd;
            std::mt19937 gen(rd());
            std::uniform_int_distribution<> time(a, b);
            CDateTime delta = time(gen);
            return Date + (CDateTime) (delta / 86400);
        }

        //--------------------------------------------------------------------------------------------------------------

        //-- CWebService -----------------------------------------------------------------------------------------------

        //--------------------------------------------------------------------------------------------------------------

        CWebService::CWebService(CModuleProcess *AProcess) : CApostolModule(AProcess, "web service") {
            m_Headers.Add("Authorization");
            m_Headers.Add("Session");
            m_Headers.Add("Secret");
            m_Headers.Add("Nonce");
            m_Headers.Add("Signature");

            m_FixedDate = Now();

            CWebService::InitMethods();
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::InitMethods() {
#if defined(_GLIBCXX_RELEASE) && (_GLIBCXX_RELEASE >= 9)
            m_pMethods->AddObject(_T("GET")    , (CObject *) new CMethodHandler(true , [this](auto && Connection) { DoGet(Connection); }));
            m_pMethods->AddObject(_T("POST")   , (CObject *) new CMethodHandler(true , [this](auto && Connection) { DoPost(Connection); }));
            m_pMethods->AddObject(_T("OPTIONS"), (CObject *) new CMethodHandler(true , [this](auto && Connection) { DoOptions(Connection); }));
            m_pMethods->AddObject(_T("HEAD")   , (CObject *) new CMethodHandler(true , [this](auto && Connection) { DoHead(Connection); }));
            m_pMethods->AddObject(_T("PUT")    , (CObject *) new CMethodHandler(false, [this](auto && Connection) { MethodNotAllowed(Connection); }));
            m_pMethods->AddObject(_T("DELETE") , (CObject *) new CMethodHandler(false, [this](auto && Connection) { MethodNotAllowed(Connection); }));
            m_pMethods->AddObject(_T("TRACE")  , (CObject *) new CMethodHandler(false, [this](auto && Connection) { MethodNotAllowed(Connection); }));
            m_pMethods->AddObject(_T("PATCH")  , (CObject *) new CMethodHandler(false, [this](auto && Connection) { MethodNotAllowed(Connection); }));
            m_pMethods->AddObject(_T("CONNECT"), (CObject *) new CMethodHandler(false, [this](auto && Connection) { MethodNotAllowed(Connection); }));
#else
            m_pMethods->AddObject(_T("GET"), (CObject *) new CMethodHandler(true, std::bind(&CWebService::DoGet, this, _1)));
            m_pMethods->AddObject(_T("POST"), (CObject *) new CMethodHandler(true, std::bind(&CWebService::DoPost, this, _1)));
            m_pMethods->AddObject(_T("OPTIONS"), (CObject *) new CMethodHandler(true, std::bind(&CWebService::DoOptions, this, _1)));
            m_pMethods->AddObject(_T("HEAD"), (CObject *) new CMethodHandler(true, std::bind(&CWebService::DoHead, this, _1)));
            m_pMethods->AddObject(_T("PUT"), (CObject *) new CMethodHandler(false, std::bind(&CWebService::MethodNotAllowed, this, _1)));
            m_pMethods->AddObject(_T("DELETE"), (CObject *) new CMethodHandler(false, std::bind(&CWebService::MethodNotAllowed, this, _1)));
            m_pMethods->AddObject(_T("TRACE"), (CObject *) new CMethodHandler(false, std::bind(&CWebService::MethodNotAllowed, this, _1)));
            m_pMethods->AddObject(_T("PATCH"), (CObject *) new CMethodHandler(false, std::bind(&CWebService::MethodNotAllowed, this, _1)));
            m_pMethods->AddObject(_T("CONNECT"), (CObject *) new CMethodHandler(false, std::bind(&CWebService::MethodNotAllowed, this, _1)));
#endif
        }
        //--------------------------------------------------------------------------------------------------------------

        CReply::CStatusType CWebService::ErrorCodeToStatus(int ErrorCode) {
            CReply::CStatusType Status = CReply::ok;

            if (ErrorCode != 0) {
                switch (ErrorCode) {
                    case 401:
                        Status = CReply::unauthorized;
                        break;

                    case 403:
                        Status = CReply::forbidden;
                        break;

                    case 404:
                        Status = CReply::not_found;
                        break;

                    case 500:
                        Status = CReply::internal_server_error;
                        break;

                    default:
                        Status = CReply::bad_request;
                        break;
                }
            }

            return Status;
        }
        //--------------------------------------------------------------------------------------------------------------

        int CWebService::CheckError(const CJSON &Json, CString &ErrorMessage, bool RaiseIfError) {
            int ErrorCode = 0;

            if (Json.HasOwnProperty(_T("error"))) {
                const auto& error = Json[_T("error")];

                if (error.HasOwnProperty(_T("code"))) {
                    ErrorCode = error[_T("code")].AsInteger();
                } else {
                    ErrorCode = 40000;
                }

                if (error.HasOwnProperty(_T("message"))) {
                    ErrorMessage = error[_T("message")].AsString();
                } else {
                    ErrorMessage = _T("Invalid request.");
                }

                if (RaiseIfError)
                    throw EDBError(ErrorMessage.c_str());

                if (ErrorCode >= 10000)
                    ErrorCode = ErrorCode / 100;
            }

            return ErrorCode;
        }
        //--------------------------------------------------------------------------------------------------------------

        int CWebService::CheckOAuth2Error(const CJSON &Json, CString &Error, CString &ErrorDescription) {
            int ErrorCode = 0;

            if (Json.HasOwnProperty(_T("error"))) {
                const auto& error = Json[_T("error")];

                if (error.HasOwnProperty(_T("code"))) {
                    ErrorCode = error[_T("code")].AsInteger();
                } else {
                    ErrorCode = 400;
                }

                if (error.HasOwnProperty(_T("error"))) {
                    Error = error[_T("error")].AsString();
                } else {
                    Error = _T("invalid_request");
                }

                if (error.HasOwnProperty(_T("message"))) {
                    ErrorDescription = error[_T("message")].AsString();
                } else {
                    ErrorDescription = _T("Invalid request.");
                }
            }

            return ErrorCode;
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::AfterQueryWS(CHTTPServerConnection *AConnection, const CString &Path, const CJSON &Payload) {

            auto lpSession = CSession::FindOfConnection(AConnection);

            auto SignIn = [lpSession](const CJSON &Payload) {

                const auto& Session = Payload[_T("session")].AsString();
                const auto& Secret = Payload[_T("secret")].AsString();

                lpSession->Session() = Session;
                lpSession->Secret() = Secret;
            };

            auto SignOut = [lpSession](const CJSON &Payload) {
                lpSession->Session().Clear();
                lpSession->Secret().Clear();
            };

            if (Path == _T("/sign/in")) {

                SignIn(Payload);

            } else if (Path == _T("/sign/out")) {

                SignOut(Payload);

            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::AfterQuery(CHTTPServerConnection *AConnection, const CString &Path, const CJSON &Payload) {

            if (Path == _T("/sign/in")) {

                SetAuthorizationData(AConnection, Payload);

            } else if (Path == _T("/sign/in/token")) {

                SetAuthorizationData(AConnection, Payload);

            } else if (Path == _T("/sign/out")) {

                auto LReply = AConnection->Reply();

                LReply->SetCookie(_T("SID"), _T("null"), _T("/"), -1);

            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoPostgresQueryExecuted(CPQPollQuery *APollQuery) {
            clock_t start = clock();

            auto LResult = APollQuery->Results(0);

            if (LResult->ExecStatus() != PGRES_TUPLES_OK) {
                QueryException(APollQuery, Delphi::Exception::EDBError(LResult->GetErrorMessage()));
                return;
            }

            CString ErrorMessage;

            auto LConnection = dynamic_cast<CHTTPServerConnection *> (APollQuery->PollConnection());

            if (LConnection != nullptr) {

                const auto& Path = LConnection->Data()["path"].Lower();
                const auto IsArray = Path.Find(_T("/list")) != CString::npos;

                if (LConnection->Protocol() == pWebSocket ) {

                    auto LWSRequest = LConnection->WSRequest();
                    auto LWSReply = LConnection->WSReply();

                    const CString LRequest(LWSRequest->Payload());

                    CWSMessage wsmRequest;
                    CWSProtocol::Request(LRequest, wsmRequest);

                    CWSMessage wsmResponse;
                    CWSProtocol::PrepareResponse(wsmRequest, wsmResponse);

                    CReply::CStatusType LStatus = CReply::bad_request;

                    try {
                        CString jsonString;
                        PQResultToJson(LResult, jsonString, IsArray);

                        wsmResponse.Payload << jsonString;

                        if (LResult->nTuples() == 1) {
                            wsmResponse.ErrorCode = CheckError(wsmResponse.Payload, wsmResponse.ErrorMessage);
                            if (wsmResponse.ErrorCode == 0) {
                                LStatus = CReply::unauthorized;
                                AfterQueryWS(LConnection, wsmRequest.Action, wsmResponse.Payload);
                            } else {
                                wsmResponse.MessageTypeId = mtCallError;
                            }
                        }
                    } catch (Delphi::Exception::Exception &E) {
                        wsmResponse.MessageTypeId = mtCallError;
                        wsmResponse.ErrorCode = LStatus;
                        wsmResponse.ErrorMessage = E.what();

                        Log()->Error(APP_LOG_EMERG, 0, E.what());
                    }

                    CString LResponse;
                    CWSProtocol::Response(wsmResponse, LResponse);
#ifdef _DEBUG
                    DebugMessage("\n[%p] [%s:%d] [%d] [WebSocket] Response:\n%s\n", LConnection, LConnection->Socket()->Binding()->PeerIP(),
                                 LConnection->Socket()->Binding()->PeerPort(), LConnection->Socket()->Binding()->Handle(), LResponse.c_str());
#endif
                    LWSReply->SetPayload(LResponse);
                    LConnection->SendWebSocket(true);

                } else {

                    auto LReply = LConnection->Reply();

                    CReply::CStatusType LStatus = CReply::ok;

                    try {
                        if (LResult->nTuples() == 1) {
                            const CJSON Payload(LResult->GetValue(0, 0));
                            LStatus = ErrorCodeToStatus(CheckError(Payload, ErrorMessage));
                            if (LStatus == CReply::ok) {
                                AfterQuery(LConnection, Path, Payload);
                            }
                        }
                        PQResultToJson(LResult, LReply->Content, IsArray);
                    } catch (Delphi::Exception::Exception &E) {
                        ErrorMessage = E.what();
                        LStatus = CReply::bad_request;
                        Log()->Error(APP_LOG_EMERG, 0, E.what());
                    }

                    const auto& LRedirect = LStatus == CReply::ok ? LConnection->Data()["redirect"] : LConnection->Data()["redirect_error"];

                    if (LRedirect.IsEmpty()) {
                        if (LStatus == CReply::ok) {
                            LConnection->SendReply(LStatus, nullptr, true);
                        } else {
                            ReplyError(LConnection, LStatus, ErrorMessage);
                        }
                    } else {
                        if (LStatus == CReply::ok) {
                            Redirect(LConnection, LRedirect, true);
                        } else {
                            switch (LStatus) {
                                case CReply::unauthorized:
                                    RedirectError(LConnection, LRedirect, LStatus, "unauthorized_client", ErrorMessage);
                                    break;

                                case CReply::forbidden:
                                    RedirectError(LConnection, LRedirect, LStatus, "access_denied", ErrorMessage);
                                    break;

                                case CReply::internal_server_error:
                                    RedirectError(LConnection, LRedirect, LStatus, "server_error", ErrorMessage);
                                    break;

                                default:
                                    RedirectError(LConnection, LRedirect, LStatus, "invalid_request", ErrorMessage);
                                    break;
                            }
                        }
                    }
                }

            } else {

                auto LJob = m_pJobs->FindJobByQuery(APollQuery);
                if (LJob == nullptr) {
                    Log()->Error(APP_LOG_EMERG, 0, _T("Job not found by Query."));
                    return;
                }

                const auto& Path = LConnection->Data()["path"].Lower();
                const auto IsArray = Path.Find(_T("/list")) != CString::npos;

                auto LReply = &LJob->Reply();
                LReply->Status = CReply::ok;

                try {
                    if (LResult->nTuples() == 1) {
                        const CJSON Payload(LResult->GetValue(0, 0));
                        LReply->Status = ErrorCodeToStatus(CheckError(Payload, ErrorMessage));
                        if (LReply->Status == CReply::ok) {
                            AfterQuery(LConnection, Path, Payload);
                        }
                    }
                    PQResultToJson(LResult, LReply->Content, IsArray);
                } catch (Delphi::Exception::Exception &E) {
                    LReply->Status = CReply::bad_request;
                    LReply->Content.Clear();
                    ExceptionToJson(LReply->Status, E, LReply->Content);
                    Log()->Error(APP_LOG_EMERG, 0, E.what());
                }
            }

            log_debug1(APP_LOG_DEBUG_CORE, Log(), 0, _T("Query executed runtime: %.2f ms."), (double) ((clock() - start) / (double) CLOCKS_PER_SEC * 1000));
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::QueryException(CPQPollQuery *APollQuery, const std::exception &e) {

            auto LConnection = dynamic_cast<CHTTPServerConnection *> (APollQuery->PollConnection());

            if (LConnection == nullptr) {
                auto LJob = m_pJobs->FindJobByQuery(APollQuery);
                if (LJob != nullptr) {
                    ExceptionToJson(CReply::internal_server_error, e, LJob->Reply().Content);
                }
            } else if (LConnection->Protocol() == pWebSocket) {
                auto LWSRequest = LConnection->WSRequest();
                auto LWSReply = LConnection->WSReply();

                const CString LRequest(LWSRequest->Payload());

                CWSMessage wsmRequest;
                CWSProtocol::Request(LRequest, wsmRequest);

                CWSMessage wsmResponse;
                CString LResponse;

                CJSON LJson;

                CWSProtocol::PrepareResponse(wsmRequest, wsmResponse);

                wsmResponse.MessageTypeId = mtCallError;
                wsmResponse.ErrorCode = CReply::internal_server_error;
                wsmResponse.ErrorMessage = e.what();

                CWSProtocol::Response(wsmResponse, LResponse);
#ifdef _DEBUG
                DebugMessage("\n[%p] [%s:%d] [%d] [WebSocket] Response:\n%s\n", LConnection,
                             LConnection->Socket()->Binding()->PeerIP(),
                             LConnection->Socket()->Binding()->PeerPort(), LConnection->Socket()->Binding()->Handle(),
                             LResponse.c_str());
#endif
                LWSReply->SetPayload(LResponse);
                LConnection->SendWebSocket(true);
            } else {
                auto LReply = LConnection->Reply();

                const auto& LRedirect = LConnection->Data()["redirect_error"];

                if (!LRedirect.IsEmpty()) {
                    RedirectError(LConnection, LRedirect, CReply::internal_server_error, "server_error", e.what());
                } else {
                    ExceptionToJson(CReply::internal_server_error, e, LReply->Content);
                    LConnection->SendReply(CReply::ok, nullptr, true);
                }
            }

            Log()->Error(APP_LOG_EMERG, 0, e.what());
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoPostgresQueryException(CPQPollQuery *APollQuery, Delphi::Exception::Exception *AException) {
            QueryException(APollQuery, *AException);
        }
        //--------------------------------------------------------------------------------------------------------------

        CString CWebService::GetSession(CRequest *ARequest) {

            const auto& headerSession = ARequest->Headers.Values(_T("Session"));
            const auto& cookieSession = ARequest->Cookies.Values(_T("SID"));

            return headerSession.IsEmpty() ? cookieSession : headerSession;
        }
        //--------------------------------------------------------------------------------------------------------------

        bool CWebService::CheckSession(CRequest *ARequest, CString &Session) {

            const auto& LSession = GetSession(ARequest);

            if (LSession.Length() != 40)
                return false;

            Session = LSession;

            return true;
        }
        //--------------------------------------------------------------------------------------------------------------

        CString CWebService::CreateToken(const CCleanToken& CleanToken) {
            const auto& Providers = Server().Providers();
            const auto& Default = Providers.Default().Value();

            auto token = jwt::create()
                    .set_issuer(Default.Issuer("web"))
                    .set_audience(Default.ClientId("web"))
                    .set_issued_at(std::chrono::system_clock::now())
                    .set_expires_at(std::chrono::system_clock::now() + std::chrono::seconds{3600})
                    .sign(jwt::algorithm::hs256{std::string(Default.Secret("web"))});

            return token;
        }
        //--------------------------------------------------------------------------------------------------------------

        CString CWebService::VerifyToken(const CString &Token) {

            const auto& GetSecret = [](const CProvider &Provider, const CString &Application) {
                const auto &Secret = Provider.Secret(Application);
                if (Secret.IsEmpty())
                    throw ExceptionFrm("Not found Secret for \"%s:%s\"",
                                       Provider.Name.c_str(),
                                       Application.c_str()
                    );
                return Secret;
            };

            auto decoded = jwt::decode(Token);
            const auto& aud = CString(decoded.get_audience());

            CString Application;

            const auto& Providers = Server().Providers();

            const auto Index = OAuth2::Helper::ProviderByClientId(Providers, aud, Application);
            if (Index == -1)
                throw COAuth2Error(_T("Not found provider by Client ID."));

            const auto& Provider = Providers[Index].Value();

            const auto& iss = CString(decoded.get_issuer());
            const CStringList& Issuers = Provider.GetIssuers(Application);
            if (Issuers[iss].IsEmpty())
                throw jwt::token_verification_exception("Token doesn't contain the required issuer.");

            const auto& alg = decoded.get_algorithm();
            const auto& ch = alg.substr(0, 2);

            const auto& Secret = GetSecret(Provider, Application);

            if (ch == "HS") {
                if (alg == "HS256") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::hs256{Secret});
                    verifier.verify(decoded);

                    return Token; // if algorithm HS256
                } else if (alg == "HS384") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::hs384{Secret});
                    verifier.verify(decoded);
                } else if (alg == "HS512") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::hs512{Secret});
                    verifier.verify(decoded);
                }
            } else if (ch == "RS") {

                const auto& kid = decoded.get_key_id();
                const auto& key = OAuth2::Helper::GetPublicKey(Providers, kid);

                if (alg == "RS256") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::rs256{key});
                    verifier.verify(decoded);
                } else if (alg == "RS384") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::rs384{key});
                    verifier.verify(decoded);
                } else if (alg == "RS512") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::rs512{key});
                    verifier.verify(decoded);
                }
            } else if (ch == "ES") {

                const auto& kid = decoded.get_key_id();
                const auto& key = OAuth2::Helper::GetPublicKey(Providers, kid);

                if (alg == "ES256") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::es256{key});
                    verifier.verify(decoded);
                } else if (alg == "ES384") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::es384{key});
                    verifier.verify(decoded);
                } else if (alg == "ES512") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::es512{key});
                    verifier.verify(decoded);
                }
            } else if (ch == "PS") {

                const auto& kid = decoded.get_key_id();
                const auto& key = OAuth2::Helper::GetPublicKey(Providers, kid);

                if (alg == "PS256") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::ps256{key});
                    verifier.verify(decoded);
                } else if (alg == "PS384") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::ps384{key});
                    verifier.verify(decoded);
                } else if (alg == "PS512") {
                    auto verifier = jwt::verify()
                            .allow_algorithm(jwt::algorithm::ps512{key});
                    verifier.verify(decoded);
                }
            }

            const auto& Result = CCleanToken(R"({"alg":"HS256","typ":"JWT"})", decoded.get_payload(), true);

            return Result.Sign(jwt::algorithm::hs256{Secret});
        }
        //--------------------------------------------------------------------------------------------------------------

        bool CWebService::CheckAuthorizationData(CRequest *ARequest, CAuthorization &Authorization) {

            const auto &LHeaders = ARequest->Headers;
            const auto &LCookies = ARequest->Cookies;

            const auto &LAuthorization = LHeaders.Values(_T("Authorization"));

            if (LAuthorization.IsEmpty()) {

                const auto &headerSession = LHeaders.Values(_T("Session"));
                const auto &headerSecret = LHeaders.Values(_T("Secret"));

                Authorization.Username = headerSession;
                Authorization.Password = headerSecret;

                if (Authorization.Username.IsEmpty() || Authorization.Password.IsEmpty())
                    return false;

                Authorization.Schema = CAuthorization::asBasic;
                Authorization.Type = CAuthorization::atSession;

            } else {
                Authorization << LAuthorization;
            }

            return true;
        }
        //--------------------------------------------------------------------------------------------------------------

        int CWebService::NeedAuthorization(const CString &Path, const CString &Ext) {

            if (Path.SubString(0, 9) == _T("/welcome/"))
                return -2;

            if (Path.SubString(0, 6) == _T("/sign/"))
                return -3;

            if (Path.SubString(0, 7) == _T("/error/"))
                return -4;

            if (Path.SubString(0, 7) == _T("/oauth/"))
                return -5;

            return (Ext == _T(".html") ? 1 : 0);
        }
        //--------------------------------------------------------------------------------------------------------------

        bool CWebService::CheckAuthorization(CHTTPServerConnection *AConnection, CAuthorization &Authorization) {

            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            try {
                if (CheckAuthorizationData(LRequest, Authorization)) {
                    if (Authorization.Schema == CAuthorization::asBearer) {
                        Authorization.Token = VerifyToken(Authorization.Token);
                        return true;
                    }
                }

                if (Authorization.Schema == CAuthorization::asBasic)
                    AConnection->Data().Values("Authorization", "Basic");

                ReplyError(AConnection, CReply::unauthorized, "Unauthorized.");
            } catch (jwt::token_expired_exception &e) {
                ReplyError(AConnection, CReply::forbidden, e.what());
            } catch (jwt::token_verification_exception &e) {
                ReplyError(AConnection, CReply::bad_request, e.what());
            } catch (CAuthorizationError &e) {
                ReplyError(AConnection, CReply::bad_request, e.what());
            } catch (std::exception &e) {
                ReplyError(AConnection, CReply::bad_request, e.what());
            }

            return false;
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::LoadProviders() {
            const CString pathCerts = Config()->Prefix() + _T("certs/");
            const CString lockFile = pathCerts + "lock";
            if (!FileExists(lockFile.c_str())) {
                auto& Providers = Server().Providers();
                for (int i = 0; i < Providers.Count(); i++) {
                    auto &Provider = Providers[i].Value();
                    if (FileExists(CString(pathCerts + Provider.Name).c_str())) {
                        Provider.Keys.Clear();
                        Provider.Keys.LoadFromFile(CString(pathCerts + Provider.Name).c_str());
                    }
                }
            } else {
                m_FixedDate = Now() + (CDateTime) 1 / 86400; // 1 sec
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::Identifier(CHTTPServerConnection *AConnection, const CString &Identifier) {

            auto OnExecuted = [this, AConnection](CPQPollQuery *APollQuery) {

                auto LReply = AConnection->Reply();
                auto LResult = APollQuery->Results(0);

                CString ErrorMessage;
                CReply::CStatusType LStatus = CReply::internal_server_error;

                try {
                    if (LResult->ExecStatus() != PGRES_TUPLES_OK)
                        throw Delphi::Exception::EDBError(LResult->GetErrorMessage());

                    const CJSON Payload(LResult->GetValue(0, 0));
                    LStatus = ErrorCodeToStatus(CheckError(Payload, ErrorMessage));
                    PQResultToJson(LResult, LReply->Content);
                } catch (Delphi::Exception::Exception &E) {
                    LReply->Content.Clear();
                    ExceptionToJson(LStatus, E, LReply->Content);
                    Log()->Error(APP_LOG_EMERG, 0, E.what());
                }

                AConnection->SendReply(LStatus, nullptr, true);
            };

            auto OnException = [this, AConnection](CPQPollQuery *APollQuery, Delphi::Exception::Exception *AException) {

                auto LReply = AConnection->Reply();

                LReply->Content.Clear();
                ExceptionToJson(CReply::internal_server_error, *AException, LReply->Content);
                AConnection->SendStockReply(CReply::ok, true);

                Log()->Error(APP_LOG_EMERG, 0, AException->what());

            };

            CStringList SQL;

            SQL.Add(CString().Format("SELECT * FROM daemon.identifier(%s);", PQQuoteLiteral(Identifier).c_str()));

            if (!ExecSQL(SQL, AConnection, OnExecuted, OnException)) {
                AConnection->SendStockReply(CReply::service_unavailable);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::Authorize(CHTTPServerConnection *AConnection, const CString &Session, const CString &Path,
                const CString &Resource) {

            auto OnExecuted = [this, AConnection](CPQPollQuery *APollQuery) {

                auto LReply = AConnection->Reply();

                const auto& LSession = AConnection->Data()["session"];
                const auto& LPath = AConnection->Data()["path"];
                const auto& LResource = AConnection->Data()["resource"];

                CPQResult *Result;
                CStringList SQL;

                try {
                    for (int I = 0; I < APollQuery->Count(); I++) {
                        Result = APollQuery->Results(I);

                        if (Result->ExecStatus() != PGRES_TUPLES_OK)
                            throw Delphi::Exception::EDBError(Result->GetErrorMessage());

                        CString ErrorMessage;

                        const CJSON Payload(Result->GetValue(0, 0));
                        if (CheckError(Payload, ErrorMessage) == 0) {
                            if (LPath == _T("/")) {
                                AConnection->Data().Values("redirect", "/dashboard/");
                                SetAuthorizationData(AConnection, Payload);
                                Redirect(AConnection, AConnection->Data()["redirect"], true);
                            } else {
                                SendResource(AConnection, LResource, _T("text/html"), true);
                            }

                            return;
                        } else {
                            LReply->SetCookie(_T("SID"), _T("null"), _T("/"), -1);

                            if (!ErrorMessage.IsEmpty())
                                Log()->Error(APP_LOG_INFO, 0, ErrorMessage.c_str());
                        }
                    }
                } catch (std::exception &e) {
                    Log()->Error(APP_LOG_EMERG, 0, e.what());
                }

                Redirect(AConnection, _T("/welcome/"),true);
            };

            auto OnException = [this, AConnection](CPQPollQuery *APollQuery, Delphi::Exception::Exception *AException) {

                Log()->Error(APP_LOG_EMERG, 0, AException->what());
                AConnection->SendStockReply(CReply::internal_server_error, true);

            };

            CStringList SQL;

            SQL.Add(CString().Format("SELECT * FROM daemon.authorize('%s');", Session.c_str()));

            AConnection->Data().Values("session", Session);
            AConnection->Data().Values("path", Path);
            AConnection->Data().Values("resource", Resource);

            if (!ExecSQL(SQL, nullptr, OnExecuted, OnException)) {
                AConnection->SendStockReply(CReply::service_unavailable);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::UnauthorizedFetch(CHTTPServerConnection *AConnection, const CString &Path, const CString &Payload,
                const CString &Agent, const CString &Host) {

            CStringList SQL;

            SQL.Add(CString().Format("SELECT * FROM daemon.unauthorized_fetch(%s, '%s'::jsonb, %s, %s);",
                                     PQQuoteLiteral(Path).c_str(),
                                     Payload.IsEmpty() ? "{}" : Payload.c_str(),
                                     PQQuoteLiteral(Agent).c_str(),
                                     PQQuoteLiteral(Host).c_str()
            ));

            AConnection->Data().Values("authorized", "false");
            AConnection->Data().Values("signature", "false");
            AConnection->Data().Values("path", Path);

            if (!StartQuery(AConnection, SQL)) {
                AConnection->SendStockReply(CReply::service_unavailable);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::AuthorizedFetch(CHTTPServerConnection *AConnection, const CAuthorization &Authorization,
                const CString &Path, const CString &Payload, const CString &Agent, const CString &Host) {

            CStringList SQL;

            if (Authorization.Schema == CAuthorization::asBearer) {

                SQL.Add(CString().Format("SELECT * FROM daemon.fetch(%s, %s, '%s'::jsonb, %s, %s);",
                                         PQQuoteLiteral(Authorization.Token).c_str(),
                                         PQQuoteLiteral(Path).c_str(),
                                         Payload.IsEmpty() ? "{}" : Payload.c_str(),
                                         PQQuoteLiteral(Agent).c_str(),
                                         PQQuoteLiteral(Host).c_str()
                ));

            } else if (Authorization.Schema == CAuthorization::asBasic) {

                SQL.Add(CString().Format("SELECT * FROM daemon.%s_fetch(%s, %s, %s, '%s'::jsonb, %s, %s);",
                                         Authorization.Type == CAuthorization::atSession ? "session" : "authorized",
                                         PQQuoteLiteral(Authorization.Username).c_str(),
                                         PQQuoteLiteral(Authorization.Password).c_str(),
                                         PQQuoteLiteral(Path).c_str(),
                                         Payload.IsEmpty() ? "{}" : Payload.c_str(),
                                         PQQuoteLiteral(Agent).c_str(),
                                         PQQuoteLiteral(Host).c_str()
                ));

            } else {

                return UnauthorizedFetch(AConnection, Path, Payload, Agent, Host);

            }

            AConnection->Data().Values("authorized", "true");
            AConnection->Data().Values("signature", "false");
            AConnection->Data().Values("path", Path);

            if (!StartQuery(AConnection, SQL)) {
                AConnection->SendStockReply(CReply::service_unavailable);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::SignedFetch(CHTTPServerConnection *AConnection, const CString &Path, const CString &Payload,
                const CString &Session, const CString &Nonce, const CString &Signature, const CString &Agent,
                const CString &Host, long int ReceiveWindow) {

            CStringList SQL;

            SQL.Add(CString().Format("SELECT * FROM daemon.signed_fetch(%s, '%s'::json, %s, %s, %s, %s, %s, INTERVAL '%d milliseconds');",
                                     PQQuoteLiteral(Path).c_str(),
                                     Payload.IsEmpty() ? "{}" : Payload.c_str(),
                                     PQQuoteLiteral(Session).c_str(),
                                     PQQuoteLiteral(Nonce).c_str(),
                                     PQQuoteLiteral(Signature).c_str(),
                                     PQQuoteLiteral(Agent).c_str(),
                                     PQQuoteLiteral(Host).c_str(),
                                     ReceiveWindow
            ));

            AConnection->Data().Values("authorized", "true");
            AConnection->Data().Values("signature", "true");
            AConnection->Data().Values("path", Path);

            if (!StartQuery(AConnection, SQL)) {
                AConnection->SendStockReply(CReply::service_unavailable);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoSessionDisconnected(CObject *Sender) {
            auto LConnection = dynamic_cast<CHTTPServerConnection *>(Sender);
            if (LConnection != nullptr) {
                auto LSession = m_SessionManager.FindByConnection(LConnection);
                if (LSession != nullptr) {
                    Log()->Message(_T("[%s:%d] WebSocket Session %s closed connection."), LConnection->Socket()->Binding()->PeerIP(),
                                   LConnection->Socket()->Binding()->PeerPort(),
                                   LSession->Identity().IsEmpty() ? "(empty)" : LSession->Identity().c_str());
                    delete LSession;
                } else {
                    Log()->Message(_T("[%s:%d] WebSocket Session closed connection."), LConnection->Socket()->Binding()->PeerIP(),
                                   LConnection->Socket()->Binding()->PeerPort());
                }
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoFetch(CHTTPServerConnection *AConnection, const CString &Path) {

            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            if (Path == "/identifier") {

                const auto& Value = LRequest->Params["value"];

                if (Value.IsEmpty()) {
                    AConnection->SendStockReply(CReply::bad_request);
                    return;
                }

                Identifier(AConnection, Value);
                return;
            }

            const auto& LContentType = LRequest->Headers.Values(_T("Content-Type")).Lower();
            const auto IsJson = (LContentType.Find(_T("application/json")) != CString::npos);

            CJSON Json;
            if (!IsJson) {
                ContentToJson(LRequest, Json);
            }

            const auto& LPayload = IsJson ? LRequest->Content : Json.ToString();
            const auto& LAgent = GetUserAgent(AConnection);
            const auto& LHost = GetHost(AConnection);

            try {
                CAuthorization LAuthorization;
                if (CheckAuthorization(AConnection, LAuthorization)) {
                    AuthorizedFetch(AConnection, LAuthorization, Path, LPayload, LAgent, LHost);
                }
            } catch (std::exception &e) {
                AConnection->CloseConnection(true);
                AConnection->SendStockReply(CReply::bad_request);
                Log()->Error(APP_LOG_EMERG, 0, e.what());
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::RedirectError(CHTTPServerConnection *AConnection, const CString &Location, int ErrorCode, const CString &Error, const CString &Message) {
            CString ErrorLocation(Location);

            ErrorLocation << "?code=" << ErrorCode;
            ErrorLocation << "&error=" << Error;
            ErrorLocation << "&error_description=" << CHTTPServer::URLEncode(Message);

            Redirect(AConnection, ErrorLocation, true);
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::ReplyError(CHTTPServerConnection *AConnection, CReply::CStatusType ErrorCode, const CString &Message) {
            auto LReply = AConnection->Reply();

            if (ErrorCode == CReply::unauthorized) {
                CReply::AddUnauthorized(LReply, AConnection->Data()["Authorization"] != "Basic", "invalid_client", Message.c_str());
            }

            LReply->Content.Clear();
            LReply->Content.Format(R"({"error": {"code": %u, "message": "%s"}})", ErrorCode, Delphi::Json::EncodeJsonString(Message).c_str());

            AConnection->SendReply(ErrorCode, nullptr, true);
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::OAuth2Error(CHTTPServerConnection *AConnection, int ErrorCode, const CString &Error, const CString &Message) {
            auto LReply = AConnection->Reply();

            CReply::CStatusType Status = ErrorCodeToStatus(ErrorCode);

            if (ErrorCode == CReply::unauthorized) {
                CReply::AddUnauthorized(LReply, true, "access_denied", Message.c_str());
            }

            LReply->Content.Clear();
            LReply->Content.Format(R"({"error": "%s", "error_description": "%s"})",
                    Error.c_str(), Delphi::Json::EncodeJsonString(Message).c_str());

            AConnection->SendReply(Status, nullptr, true);
        };
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoToken(CHTTPServerConnection *AConnection) {

            auto OnExecuted = [AConnection, this](CPQPollQuery *APollQuery) {

                auto LReply = AConnection->Reply();
                auto LResult = APollQuery->Results(0);

                CString Error;
                CString ErrorDescription;

                CReply::CStatusType LStatus;

                try {
                    if (LResult->ExecStatus() != PGRES_TUPLES_OK)
                        throw Delphi::Exception::EDBError(LResult->GetErrorMessage());

                    PQResultToJson(LResult, LReply->Content);

                    const CJSON Json(LReply->Content);
                    LStatus = ErrorCodeToStatus(CheckOAuth2Error(Json, Error, ErrorDescription));

                    if (LStatus == CReply::ok) {
                        AConnection->SendReply(LStatus, nullptr, true);
                    } else {
                        OAuth2Error(AConnection, LStatus, Error, ErrorDescription);
                    }
                } catch (Delphi::Exception::Exception &E) {
                    OAuth2Error(AConnection, 500, "server_error", E.what());
                    Log()->Error(APP_LOG_EMERG, 0, E.what());
                }
            };

            auto OnException = [AConnection, this](CPQPollQuery *APollQuery, Delphi::Exception::Exception *AException) {
                OAuth2Error(AConnection, 500, "server_error", *AException->what());
                Log()->Error(APP_LOG_EMERG, 0, AException->what());
            };

            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            CJSON Json;
            ContentToJson(LRequest, Json);

            const auto &client_id = Json["client_id"].AsString();
            const auto &client_secret = Json["client_secret"].AsString();
            const auto &grant_type = Json["grant_type"].AsString();
            const auto &redirect_uri = Json["redirect_uri"].AsString();

            const auto &Providers = Server().Providers();

            CAuthorization Authorization;
            const auto &LAuthorization = LRequest->Headers.Values(_T("Authorization"));

            if (LAuthorization.IsEmpty()) {
                const auto &Provider = Providers.Default().Value();

                Authorization.Schema = CAuthorization::asBasic;
                Authorization.Username = client_id.IsEmpty() ? Provider.ClientId("web") : client_id;
                Authorization.Password = client_secret.IsEmpty() ? Provider.Secret("web") : client_secret;
            } else {
                Authorization << LAuthorization;
            }

            if (Authorization.Schema != CAuthorization::asBasic || Authorization.Username.IsEmpty()) {
                OAuth2Error(AConnection, 403, "access_denied", "Access denied.");
                return;
            }

            if (Authorization.Password.IsEmpty()) {
                CString Application;
                const auto Index = OAuth2::Helper::ProviderByClientId(Providers, Authorization.Username, Application);

                if (Index != -1 && Authorization.Password.IsEmpty()) {
                    const auto &Provider = Providers[Index].Value();
                    Authorization.Password = Provider.Secret(Application);
                }
            }

            const auto &Agent = GetUserAgent(AConnection);
            const auto &Host = GetHost(AConnection);

            CStringList SQL;

            SQL.Add(CString().Format("SELECT * FROM daemon.token(%s, %s, '%s'::jsonb, %s, %s);",
                                     PQQuoteLiteral(Authorization.Username).c_str(),
                                     PQQuoteLiteral(Authorization.Password).c_str(),
                                     Json.ToString().c_str(),
                                     PQQuoteLiteral(Agent).c_str(),
                                     PQQuoteLiteral(Host).c_str()
            ));

            if (!ExecSQL(SQL, AConnection, OnExecuted, OnException)) {
                OAuth2Error(AConnection, 400, "temporarily_unavailable", "Temporarily unavailable.");
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoOAuth2(CHTTPServerConnection *AConnection) {

            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            LReply->ContentType = CReply::json;

            CStringList LRouts;
            SplitColumns(LRequest->Location.pathname, LRouts, '/');

            if (LRouts.Count() < 2) {
                OAuth2Error(AConnection, 404, "invalid_request", "Not found.");
                return;
            }

            AConnection->Data().Values("oauth2", "true");
            AConnection->Data().Values("path", LRequest->Location.pathname);

            try {
                const auto &Action = LRouts[1].Lower();

                if (Action == "token") {
                    DoToken(AConnection);
                } else {
                    OAuth2Error(AConnection, 404, "invalid_request", "Not found.");
                }
            } catch (std::exception &e) {
                OAuth2Error(AConnection, 400, "invalid_request", e.what());
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::SignInToken(CHTTPServerConnection *AConnection, const CJSON &Token) {

            const auto &errorLocation = AConnection->Data()["redirect_error"];

            try {
                const auto &tokenType = Token["token_type"].AsString();
                const auto &idToken = Token["id_token"].AsString();

                CAuthorization Authorization;

                try {
                    Authorization << (tokenType + " " + idToken);

                    if (Authorization.Schema == CAuthorization::asBearer) {
                        Authorization.Token = VerifyToken(Authorization.Token);
                    }

                    const auto &Agent = GetUserAgent(AConnection);
                    const auto &Host = GetHost(AConnection);

                    CStringList SQL;

                    SQL.Add(CString().Format("SELECT * FROM daemon.signin(%s, %s, %s);",
                                             PQQuoteLiteral(Authorization.Token).c_str(),
                                             PQQuoteLiteral(Agent).c_str(),
                                             PQQuoteLiteral(Host).c_str()
                    ));

                    AConnection->Data().Values("authorized", "false");
                    AConnection->Data().Values("signature", "false");
                    AConnection->Data().Values("path", "/sign/in/token");

                    if (!ExecSQL(SQL, AConnection)) {
                        RedirectError(AConnection, errorLocation, 400, "temporarily_unavailable", "Temporarily unavailable.");
                    }

                } catch (jwt::token_expired_exception &e) {
                    RedirectError(AConnection, errorLocation, 403, "invalid_token", e.what());
                } catch (jwt::token_verification_exception &e) {
                    RedirectError(AConnection, errorLocation, 401, "invalid_token", e.what());
                } catch (CAuthorizationError &e) {
                    RedirectError(AConnection, errorLocation, 401, "unauthorized_client", e.what());
                } catch (std::exception &e) {
                    RedirectError(AConnection, errorLocation, 400, "invalid_request", e.what());
                }
            } catch (Delphi::Exception::Exception &e) {
                RedirectError(AConnection, errorLocation, 500, "server_error", e.what());
                Log()->Error(APP_LOG_INFO, 0, "[Token] Message: %s", e.what());
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::SetAuthorizationData(CHTTPServerConnection *AConnection, const CJSON &Payload) {

            auto LReply = AConnection->Reply();

            const auto &session = Payload[_T("session")].AsString();
            if (!session.IsEmpty())
                LReply->SetCookie(_T("SID"), session.c_str(), _T("/"), 60 * 86400);

            CString Redirect = AConnection->Data()["redirect"];
            if (!Redirect.IsEmpty()) {

                const auto &access_token = Payload[_T("access_token")].AsString();
                const auto &token_type = Payload[_T("token_type")].AsString();
                const auto &expires_in = Payload[_T("expires_in")].AsString();
                const auto &state = Payload[_T("state")].AsString();

                Redirect << "#access_token=" << access_token;
                Redirect << "&token_type=" << token_type;
                Redirect << "&expires_in=" << expires_in;
                Redirect << "&session=" << session;

                if (!state.IsEmpty())
                    Redirect << "&state=" << CHTTPServer::URLEncode(state);

                AConnection->Data().Values("redirect", Redirect);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::ParseString(const CString &String, const CStringList &Strings, CStringList &Valid, CStringList &Invalid) {
            Valid.Clear();
            Invalid.Clear();

            if (!String.IsEmpty()) {
                Valid.LineBreak(", ");
                Invalid.LineBreak(", ");

                CStringList Scopes;
                SplitColumns(String, Scopes, ' ');

                for (int i = 0; i < Scopes.Count(); i++) {
                    if (Strings.IndexOfName(Scopes[i]) == -1) {
                        Invalid.Add(Scopes[i]);
                    } else {
                        Valid.Add(Scopes[i]);
                    }
                }
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoAuthorize(CHTTPServerConnection *AConnection) {

            auto OnRequestToken = [this](CHTTPClient *Sender, CRequest *Request) {

                const auto &token_uri = Sender->Data()["token_uri"];
                const auto &code = Sender->Data()["code"];
                const auto &client_id = Sender->Data()["client_id"];
                const auto &client_secret = Sender->Data()["client_secret"];
                const auto &redirect_uri = Sender->Data()["redirect_uri"];
                const auto &grant_type = Sender->Data()["grant_type"];

                Request->Headers.AddPair(_T("Content-Type"), _T("application/x-www-form-urlencoded"));

                Request->Content = _T("client_id=");
                Request->Content << CHTTPServer::URLEncode(client_id);

                Request->Content << _T("&client_secret=");
                Request->Content << CHTTPServer::URLEncode(client_secret);

                Request->Content << _T("&grant_type=");
                Request->Content << grant_type;

                Request->Content << _T("&code=");
                Request->Content << CHTTPServer::URLEncode(code);

                Request->Content << _T("&redirect_uri=");
                Request->Content << CHTTPServer::URLEncode(redirect_uri);

                CRequest::Prepare(Request, _T("POST"), token_uri.c_str());

                DebugRequest(Request);
            };

            auto OnReplyToken = [this, AConnection](CTCPConnection *Sender) {

                auto LConnection = dynamic_cast<CHTTPClientConnection *> (Sender);
                auto LReply = LConnection->Reply();

                DebugReply(LReply);

                const CJSON Json(LReply->Content);

                CString errorLocation = "/oauth/error";

                AConnection->Data().Values("redirect", "/dashboard/");
                AConnection->Data().Values("redirect_error", errorLocation);

                if (LReply->Status == CReply::ok) {
                    const auto &Provider = AConnection->Data()["provider"];

                    if (Provider == "default") {

                        SetAuthorizationData(AConnection, Json);

                        const auto &Location = AConnection->Data()["redirect"];
                        Redirect(AConnection, Location, true);

                    } else {

                        SignInToken(AConnection, Json);
                    }
                } else {
                    const auto &Error = Json[_T("error")].AsString();
                    const auto &ErrorMessage = Json[_T("error_description")].AsString();

                    RedirectError(AConnection, errorLocation, LReply->Status, Error, ErrorMessage);
                }

                return true;
            };

            auto OnException = [AConnection](CTCPConnection *Sender, Delphi::Exception::Exception *AException) {

                auto LConnection = dynamic_cast<CHTTPClientConnection *> (Sender);
                auto LClient = dynamic_cast<CHTTPClient *> (LConnection->Client());

                DebugReply(LConnection->Reply());

                RedirectError(AConnection, "/oauth/error", 500, "server_error", AException->what());

                Log()->Error(APP_LOG_EMERG, 0, "[%s:%d] %s", LClient->Host().c_str(), LClient->Port(),
                             AException->what());
            };

            auto SetSearch = [](const CStringList &Search, CString &Location) {
                for (int i = 0; i < Search.Count(); ++i) {
                    if (i == 0) {
                        Location << "?";
                    } else {
                        Location << "&";
                    }
                    Location << Search.Strings(i);
                }
            };

            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            LReply->ContentType = CReply::html;

            CStringList LRouts;
            SplitColumns(LRequest->Location.pathname, LRouts, '/');

            if (LRouts.Count() < 2) {
                AConnection->SendStockReply(CReply::not_found);
                return;
            }

            CString oauthLocation;
            const CString errorLocation("/oauth/error");

            CStringList Search;
            CStringList Valid;
            CStringList Invalid;

            CStringList ResponseType;
            ResponseType.Add("code");
            ResponseType.Add("token");

            CStringList AccessType;
            AccessType.Add("online");
            AccessType.Add("offline");

            const auto &Providers = Server().Providers();

            const auto &Action = LRouts[1].Lower();

            if (Action == "authorize" || Action == "auth") {

                const auto &response_type = LRequest->Params["response_type"];
                const auto &client_id = LRequest->Params["client_id"];
                const auto &access_type = LRequest->Params["access_type"];
                const auto &redirect_uri = LRequest->Params["redirect_uri"];
                const auto &scope = LRequest->Params["scope"];
                const auto &state = LRequest->Params["state"];

                if (redirect_uri.IsEmpty()) {
                    RedirectError(AConnection, errorLocation, 400, "invalid_request",
                                  CString().Format("Parameter value redirect_uri cannot be empty."));
                    return;
                }

                const auto &Provider = Providers.Default().Value();
                const auto &Application = Provider.GetClients()[client_id];

                if (Application.IsEmpty()) {
                    RedirectError(AConnection, errorLocation, 401, "invalid_client", CString().Format("The OAuth client was not found."));
                    return;
                }

                if (Provider.RedirectURI(Application).IndexOfName(redirect_uri) == -1) {
                    RedirectError(AConnection, errorLocation, 400, "invalid_request",
                                  CString().Format("Invalid parameter value for redirect_uri: Non-public domains not allowed: %s", redirect_uri.c_str()));
                    return;
                }

                ParseString(response_type, ResponseType, Valid, Invalid);

                if (Invalid.Count() > 0) {
                    RedirectError(AConnection, errorLocation, 400, "unsupported_response_type",
                                  CString().Format("Some requested response type were invalid: {valid=[%s], invalid=[%s]}",
                                                   Valid.Text().c_str(), Invalid.Text().c_str()));
                    return;
                }

                if (response_type == "token")
                    AccessType.Clear();

                if (!access_type.IsEmpty() && AccessType.IndexOfName(access_type) == -1) {
                    RedirectError(AConnection, errorLocation, 400, "invalid_request",
                                  CString().Format("Invalid access_type: %s", access_type.c_str()));
                    return;
                }

                const auto &Scopes = Provider.GetScopes(Application);
                ParseString(scope, Scopes, Valid, Invalid);

                if (Invalid.Count() > 0) {
                    RedirectError(AConnection, errorLocation, 400, "invalid_scope",
                                  CString().Format("Some requested scopes were invalid: {valid=[%s], invalid=[%s]}",
                                                   Valid.Text().c_str(), Invalid.Text().c_str()));
                    return;
                }

                oauthLocation = "/oauth/identifier";

                Search.Clear();

                Search.AddPair("client_id", client_id);
                Search.AddPair("response_type", response_type);

                if (!redirect_uri.IsEmpty())
                    Search.AddPair("redirect_uri", CHTTPServer::URLEncode(redirect_uri));
                if (!access_type.IsEmpty())
                    Search.AddPair("access_type", access_type);
                if (!scope.IsEmpty())
                    Search.AddPair("scope", CHTTPServer::URLEncode(scope));
                if (!state.IsEmpty())
                    Search.AddPair("state", CHTTPServer::URLEncode(state));

                SetSearch(Search, oauthLocation);

            } else if (Action == "code") {

                const auto &Error = LRequest->Params["error"];

                if (!Error.IsEmpty()) {
                    const auto ErrorCode = StrToIntDef(LRequest->Params["code"].c_str(), 400);
                    RedirectError(AConnection, errorLocation, ErrorCode, Error, LRequest->Params["error_description"]);
                    return;
                }

                const auto &providerName = LRouts.Count() == 3 ? LRouts[2].Lower() : "default";
                const auto &Provider = Providers[providerName].Value();

                const auto &Application = "web";

                const auto &code = LRequest->Params["code"];
                const auto &state = LRequest->Params["state"];

                CString TokenURI(Provider.TokenURI(Application));

                if (TokenURI.front() == '/') {
                    TokenURI = LRequest->Location.Origin() + TokenURI;
                }

                CLocation URI(TokenURI);

                auto LClient = GetClient(URI.hostname, URI.port);

                AConnection->Data().Values("provider", providerName);

                LClient->Data().Values("client_id", Provider.ClientId(Application));
                LClient->Data().Values("client_secret", Provider.Secret(Application));
                LClient->Data().Values("grant_type", "authorization_code");
                LClient->Data().Values("code", code);
                LClient->Data().Values("redirect_uri", LRequest->Location.Origin() + LRequest->Location.pathname);
                LClient->Data().Values("token_uri", URI.pathname);

                LClient->OnRequest(OnRequestToken);
                LClient->OnExecute(OnReplyToken);
                LClient->OnException(OnException);

                LClient->Active(true);

                return;

            } else if (Action == "callback") {

                oauthLocation = "/oauth/callback";

            }

            if (oauthLocation.IsEmpty())
                AConnection->SendStockReply(CReply::not_found);
            else
                Redirect(AConnection, oauthLocation);
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoAPI(CHTTPServerConnection *AConnection) {
            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            LReply->ContentType = CReply::json;

            CStringList LRouts;
            SplitColumns(LRequest->Location.pathname, LRouts, '/');

            if (LRouts.Count() < 3) {
                AConnection->SendStockReply(CReply::not_found);
                return;
            }

            const auto& LService = LRouts[0].Lower();
            const auto& LVersion = LRouts[1].Lower();
            const auto& LCommand = LRouts[2].Lower();

            if (LVersion == "v1") {
                m_Version = 1;
            } else if (LVersion == "v2") {
                m_Version = 2;
            }

            if (LService != "api" || (m_Version == -1)) {
                AConnection->SendStockReply(CReply::not_found);
                return;
            }

            try {
                if (LCommand == "ping") {

                    AConnection->SendStockReply(CReply::ok);

                } else if (LCommand == "time") {

                    LReply->Content << "{\"serverTime\": " << to_string(MsEpoch()) << "}";

                    AConnection->SendReply(CReply::ok);

                } else if (m_Version == 2) {

                    if (LRouts.Count() != 3) {
                        AConnection->SendStockReply(CReply::bad_request);
                        return;
                    }

                    const auto& Identity = LRouts[2];

                    if (Identity.Length() != APOSTOL_MODULE_UID_LENGTH) {
                        AConnection->SendStockReply(CReply::bad_request);
                        return;
                    }

                    auto LJob = m_pJobs->FindJobById(Identity);

                    if (LJob == nullptr) {
                        AConnection->SendStockReply(CReply::not_found);
                        return;
                    }

                    if (LJob->Reply().Content.IsEmpty()) {
                        AConnection->SendStockReply(CReply::no_content);
                        return;
                    }

                    LReply->Content = LJob->Reply().Content;

                    CReply::GetReply(LReply, CReply::ok);

                    LReply->Headers << LJob->Reply().Headers;

                    AConnection->SendReply();

                    delete LJob;

                } else {

                    CString LPath;
                    for (int I = 2; I < LRouts.Count(); ++I) {
                        LPath.Append('/');
                        LPath.Append(LRouts[I].Lower());
                    }

                    if (LPath.IsEmpty()) {
                        AConnection->SendStockReply(CReply::not_found);
                        return;
                    }

                    DoFetch(AConnection, LPath);
                }
            } catch (std::exception &e) {
                ExceptionToJson(CReply::bad_request, e, LReply->Content);

                AConnection->CloseConnection(true);
                AConnection->SendReply(CReply::ok);

                Log()->Error(APP_LOG_EMERG, 0, e.what());
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoWSSession(CHTTPServerConnection *AConnection) {

            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            LReply->ContentType = CReply::html;

            CStringList LPath;
            SplitColumns(LRequest->Location.pathname, LPath, '/');

            if (LPath.Count() < 2) {
                AConnection->SendStockReply(CReply::not_found);
                return;
            }

            const auto& LSecWebSocketKey = LRequest->Headers.Values(_T("Sec-WebSocket-Key"));
            if (LSecWebSocketKey.IsEmpty()) {
                AConnection->SendStockReply(CReply::bad_request, true);
                return;
            }

            const auto& LIdentity = LPath[1];
            const auto& LSecWebSocketProtocol = LRequest->Headers.Values(_T("Sec-WebSocket-Protocol"));

            const CString LAccept(SHA1(LSecWebSocketKey + _T("258EAFA5-E914-47DA-95CA-C5AB0DC85B11")));
            const CString LProtocol(LSecWebSocketProtocol.IsEmpty() ? "" : LSecWebSocketProtocol.SubString(0, LSecWebSocketProtocol.Find(',')));

            AConnection->SwitchingProtocols(LAccept, LProtocol);

            auto lpSession = m_SessionManager.FindByIdentity(LIdentity);
            if (lpSession == nullptr) {
                lpSession = m_SessionManager.Add(AConnection);

                CheckAuthorizationData(LRequest, lpSession->Authorization());

                lpSession->Identity() = LIdentity;
                lpSession->IP() = GetHost(AConnection);
                lpSession->Agent() = GetUserAgent(AConnection);

#if defined(_GLIBCXX_RELEASE) && (_GLIBCXX_RELEASE >= 9)
                AConnection->OnDisconnected([this](auto && Sender) { DoSessionDisconnected(Sender); });
#else
                AConnection->OnDisconnected(std::bind(&CWebService::DoSessionDisconnected, this, _1));
#endif
            } else {
                lpSession->SwitchConnection(AConnection);
                lpSession->IP() = GetHost(AConnection);
                lpSession->Agent() = GetUserAgent(AConnection);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoWebSocket(CHTTPServerConnection *AConnection) {
            auto LWSRequest = AConnection->WSRequest();
            auto LWSReply = AConnection->WSReply();

            const CString LRequest(LWSRequest->Payload());
#ifdef _DEBUG
            DebugMessage(_T("\n[%p] [%s:%d] [%d] [WebSocket] Request:\n%s\n"), AConnection, AConnection->Socket()->Binding()->PeerIP(),
                         AConnection->Socket()->Binding()->PeerPort(), AConnection->Socket()->Binding()->Handle(), LRequest.c_str());
#endif
            try {
                auto lpSession = CSession::FindOfConnection(AConnection);

                CWSMessage wsmRequest;
                CWSMessage wsmResponse;

                try {
                    CString sigData;

                    CWSProtocol::Request(LRequest, wsmRequest);

                    const auto &LAuthorization = lpSession->Authorization();

                    if (wsmRequest.MessageTypeId == mtOpen) {
                        if (wsmRequest.Payload.ValueType() == jvtObject) {
                            wsmRequest.Action = _T("/authorize");

                            lpSession->Session() = wsmRequest.Payload[_T("session")].AsString();
                            lpSession->Secret() = wsmRequest.Payload[_T("secret")].AsString();

                            if (lpSession->Session().IsEmpty() || lpSession->Secret().IsEmpty())
                                throw Delphi::Exception::Exception(_T("Session or secret cannot be empty."));

                            wsmRequest.Payload -= _T("secret");
                        } else {
                            if (LAuthorization.Schema == CAuthorization::asBasic) {
                                wsmRequest.Action = _T("/sign/in");
                                wsmRequest.Payload.Object().AddPair(_T("username"), lpSession->Authorization().Username);
                                wsmRequest.Payload.Object().AddPair(_T("password"), lpSession->Authorization().Password);
                            }
                        }

                        wsmRequest.MessageTypeId = mtCall;
                    } else if (wsmRequest.MessageTypeId == mtClose) {
                        wsmRequest.Action = _T("/sign/out");
                        wsmRequest.MessageTypeId = mtCall;
                    }

                    if (wsmRequest.MessageTypeId == mtCall) {

                        sigData = wsmRequest.Action;

                        const auto& LPayload = wsmRequest.Payload.ToString();

                        if (LAuthorization.Schema != CAuthorization::asUnknown) {
                            AuthorizedFetch(AConnection, LAuthorization, wsmRequest.Action, LPayload, lpSession->Agent(), lpSession->IP());
                        } else {
                            const auto& LNonce = to_string(MsEpoch() * 1000);

                            sigData << LNonce;
                            sigData << (LPayload.IsEmpty() ? _T("null") : LPayload);

                            const auto& LSignature = lpSession->Secret().IsEmpty() ? _T("") : hmac_sha256(lpSession->Secret(), sigData);

                            SignedFetch(AConnection, wsmRequest.Action, LPayload, lpSession->Session(), LNonce, LSignature, lpSession->Agent(), lpSession->IP());
                        }
                    } else {
                        // Ответ от устройства отправим в обработчик
                        auto LHandler = lpSession->Messages()->FindMessageById(wsmRequest.UniqueId);
                        if (Assigned(LHandler)) {
                            LHandler->Handler(AConnection);
                        }
                    }
                } catch (std::exception &e) {
                    CWSProtocol::PrepareResponse(wsmRequest, wsmResponse);

                    wsmResponse.MessageTypeId = mtCallError;
                    wsmResponse.ErrorCode = CReply::bad_request;
                    wsmResponse.ErrorMessage = e.what();

                    CString LResponse;
                    CWSProtocol::Response(wsmResponse, LResponse);

                    LWSReply->SetPayload(LResponse);
                    AConnection->SendWebSocket();

                    Log()->Error(APP_LOG_NOTICE, 0, e.what());
                }
            } catch (std::exception &e) {
                AConnection->SendWebSocketClose();
                AConnection->CloseConnection(true);

                Log()->Error(APP_LOG_EMERG, 0, e.what());
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoGet(CHTTPServerConnection *AConnection) {

            auto LRequest = AConnection->Request();

            CString LPath(LRequest->Location.pathname);

            // Request path must be absolute and not contain "..".
            if (LPath.empty() || LPath.front() != '/' || LPath.find(_T("..")) != CString::npos) {
                AConnection->SendStockReply(CReply::bad_request);
                return;
            }

            if (LPath.SubString(0, 9) == _T("/session/")) {
                DoWSSession(AConnection);
                return;
            }

            if (LPath.SubString(0, 5) == _T("/api/")) {
                DoAPI(AConnection);
                return;
            }

            if (LPath.SubString(0, 8) == _T("/oauth2/")) {
                DoAuthorize(AConnection);
                return;
            }

            CString LResource(LPath);

            // If path ends in slash.
            if (LResource.back() == '/') {
                LResource += _T("index.html");
            }

            TCHAR szBuffer[PATH_MAX] = {0};
            CString LFileExt = ExtractFileExt(szBuffer, LResource.c_str());

            if (LFileExt == LResource) {
                LFileExt = _T(".html");
                LResource += LFileExt;
            }

            const auto needAuth = NeedAuthorization(LResource, LFileExt);
            if (needAuth == 1) {
                CString LSession;
                if (CheckSession(LRequest, LSession)) {
                    Authorize(AConnection, LSession, LPath, LResource);
                } else {
                    Redirect(AConnection, _T("/welcome/"));
                }
            } else {
                SendResource(AConnection, LResource, Mapping::ExtToType(LFileExt.c_str()));
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::DoPost(CHTTPServerConnection *AConnection) {

            auto LRequest = AConnection->Request();
            auto LReply = AConnection->Reply();

            LReply->ContentType = CReply::json;

            if (LRequest->Location.pathname.SubString(0, 8) == "/oauth2/") {
                DoOAuth2(AConnection);
                return;
            }

            CStringList LRouts;
            SplitColumns(LRequest->Location.pathname, LRouts, '/');

            if (LRouts.Count() < 2) {
                AConnection->SendStockReply(CReply::not_found);
                return;
            }

            if (LRouts[1] == _T("v1")) {
                m_Version = 1;
            } else if (LRouts[1] == _T("v2")) {
                m_Version = 2;
            }

            if (LRouts[0] != _T("api") || (m_Version == -1)) {
                AConnection->SendStockReply(CReply::not_found);
                return;
            }

            CString LPath;
            for (int I = 2; I < LRouts.Count(); ++I) {
                LPath.Append('/');
                LPath.Append(LRouts[I].Lower());
            }

            if (LPath.IsEmpty()) {
                AConnection->SendStockReply(CReply::not_found);
                return;
            }

            const auto& LContentType = LRequest->Headers.Values(_T("Content-Type")).Lower();
            const auto IsJson = (LContentType.Find(_T("application/json")) != CString::npos);

            CJSON Json;
            if (!IsJson) {
                ContentToJson(LRequest, Json);
            }

            const auto& LPayload = IsJson ? LRequest->Content : Json.ToString();
            const auto& LSignature = LRequest->Headers.Values(_T("Signature"));

            const auto& LAgent = GetUserAgent(AConnection);
            const auto& LHost = GetHost(AConnection);

            try {
                if (LSignature.IsEmpty()) {
                    CAuthorization LAuthorization;
                    if (CheckAuthorization(AConnection, LAuthorization)) {
                        AuthorizedFetch(AConnection, LAuthorization, LPath, LPayload, LAgent, LHost);
                    }
                } else {
                    const auto& LSession = GetSession(LRequest);
                    const auto& LNonce = LRequest->Headers.Values(_T("Nonce"));

                    long int LReceiveWindow = 5000;
                    const auto& receiveWindow = LRequest->Params[_T("receive_window")];
                    if (!receiveWindow.IsEmpty())
                        LReceiveWindow = StrToIntDef(receiveWindow.c_str(), LReceiveWindow);

                    SignedFetch(AConnection, LPath, LPayload, LSession, LNonce, LSignature, LAgent, LHost, LReceiveWindow);
                }
            } catch (Delphi::Exception::Exception &E) {
                ExceptionToJson(CReply::bad_request, E, LReply->Content);
                AConnection->SendReply(CReply::ok);
                Log()->Error(APP_LOG_EMERG, 0, E.what());
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::Initialization(CModuleProcess *AProcess) {
            CApostolModule::Initialization(AProcess);

            if (m_Password.IsEmpty()) {
                const auto& connInfo = Config()->PostgresConnInfo();
                m_Password = PQQuoteLiteral(connInfo["password"]);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::Heartbeat() {
            auto now = Now();

            if ((now >= m_FixedDate)) {
                m_FixedDate = now + (CDateTime) 30 * 60 / 86400; // 30 min
                LoadProviders();
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CWebService::Execute(CHTTPServerConnection *AConnection) {
            switch (AConnection->Protocol()) {
                case pHTTP:
                    CApostolModule::Execute(AConnection);
                    break;
                case pWebSocket:
                    DoWebSocket(AConnection);
                    break;
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        bool CWebService::IsEnabled() {
            if (m_ModuleStatus == msUnknown)
                m_ModuleStatus = msEnabled;
            return m_ModuleStatus == msEnabled;
        }
        //--------------------------------------------------------------------------------------------------------------

        bool CWebService::CheckUserAgent(const CString &Value) {
            return IsEnabled();
        }

    }
}
}