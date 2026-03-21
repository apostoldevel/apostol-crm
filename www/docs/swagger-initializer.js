window.onload = function() {
  window.ui = SwaggerUIBundle({
    url: "/docs/api.yaml",
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    plugins: [
      SwaggerUIBundle.plugins.DownloadUrl
    ],
    layout: "StandaloneLayout",
    oauth2RedirectUrl: window.location.origin + "/docs/oauth2-redirect.html",
    initOAuth: {
      clientId: "web-example.com",
      scopes: "apostol"
    }
  });
};
