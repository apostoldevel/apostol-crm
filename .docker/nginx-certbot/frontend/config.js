var appConfig = {
    defaultLanguage: "en",

    creditsText: "Apostol CRM © 2026",
    creditsShortText: "Apostol CRM Admin Panel",

    signIn: "/signin",
    signUp: "/signup",

    confAuthorize: true,
    confCrm: false,
    confDriver: false,
    confOcpp: false,
    confAdmin: true,
    googleAuthorize: false,

    map: "google",
    mapLanguage: "en_US",

    googleClientId: null,

    ocppApiDomain: "http://localhost:8080",
    ocppApiPath: "/api/v1",
    ocppApiClientId: "web-example.com",

    apiTokenUrl: "http://localhost:8080/oauth2/token",
    apiDomain: "http://localhost:8080",
    wsDomain: "ws://localhost:8080",
    apiPath: "/api/v1",
    apiClientId: "web-example.com",

    adminReferences: {
        address: {
            extraFields: {
                country: {
                    type: "reference",
                    path: "/country/list",
                    required: true,
                },
            },
        },
        calendar: {},
        category: {},
        country: {
            extraFields: {
                alpha2: {
                    type: "string",
                    required: true
                },
                alpha3: {
                    type: "string"
                },
                decimal: {
                    type: "integer"
                },
                flag: {
                    type: "string"
                }
            }
        },
        currency: {
            extraFields: {
                digital: {
                    type: "integer"
                },
                decimal: {
                    type: "integer"
                }
            }
        },
        measure: {},
        model: {
            extraFields: {
                vendor: {
                    type: "reference",
                    path: "/vendor/list",
                    required: true,
                },
                category: {
                    type: "reference",
                    path: "/category/list",
                    required: false,
                },
            },
        },
        property: {},
        service: {
            extraFields: {
                category: {
                    type: "reference",
                    path: "/category/list",
                    required: true,
                },
                measure: {
                    type: "reference",
                    path: "/measure/list",
                    required: true,
                },
            },
        },
    },

    maxFileSize: 512000
};
