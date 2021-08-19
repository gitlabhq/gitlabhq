package main

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"

	"gitlab.com/gitlab-org/labkit/correlation"

	"github.com/dgrijalva/jwt-go"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

func okHandler(w http.ResponseWriter, _ *http.Request, _ *api.Response) {
	w.WriteHeader(201)
	fmt.Fprint(w, "{\"status\":\"ok\"}")
}

func runPreAuthorizeHandler(t *testing.T, ts *httptest.Server, suffix string, url *regexp.Regexp, apiResponse interface{}, returnCode, expectedCode int) *httptest.ResponseRecorder {
	if ts == nil {
		ts = testAuthServer(t, url, nil, returnCode, apiResponse)
		defer ts.Close()
	}

	// Create http request
	ctx := correlation.ContextWithCorrelation(context.Background(), "12345678")
	httpRequest, err := http.NewRequestWithContext(ctx, "GET", "/address", nil)
	require.NoError(t, err)
	parsedURL := helper.URLMustParse(ts.URL)
	testhelper.ConfigureSecret()
	a := api.NewAPI(parsedURL, "123", roundtripper.NewTestBackendRoundTripper(parsedURL))

	response := httptest.NewRecorder()
	a.PreAuthorizeHandler(okHandler, suffix).ServeHTTP(response, httpRequest)
	require.Equal(t, expectedCode, response.Code)
	return response
}

func TestPreAuthorizeHappyPath(t *testing.T) {
	runPreAuthorizeHandler(
		t, nil, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		&api.Response{},
		200, 201)
}

func TestPreAuthorizeSuffix(t *testing.T) {
	runPreAuthorizeHandler(
		t, nil, "/different-authorize",
		regexp.MustCompile(`/authorize\z`),
		&api.Response{},
		200, 404)
}

func TestPreAuthorizeJsonFailure(t *testing.T) {
	runPreAuthorizeHandler(
		t, nil, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		"not-json",
		200, 500)
}

func TestPreAuthorizeContentTypeFailure(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := w.Write([]byte(`{"hello":"world"}`))
		require.NoError(t, err, "write auth response")
	}))
	defer ts.Close()

	runPreAuthorizeHandler(
		t, ts, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		"",
		200, 200)
}

func TestPreAuthorizeRedirect(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/", http.StatusMovedPermanently)
	}))
	defer ts.Close()

	runPreAuthorizeHandler(t, ts, "/willredirect",
		regexp.MustCompile(`/willredirect\z`),
		"",
		301, 301)
}

func TestPreAuthorizeJWT(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token, err := jwt.Parse(r.Header.Get(secret.RequestHeader), func(token *jwt.Token) (interface{}, error) {
			// Don't forget to validate the alg is what you expect:
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
			}
			testhelper.ConfigureSecret()
			secretBytes, err := secret.Bytes()
			if err != nil {
				return nil, fmt.Errorf("read secret from file: %v", err)
			}

			return secretBytes, nil
		})
		require.NoError(t, err, "decode token")

		claims, ok := token.Claims.(jwt.MapClaims)
		require.True(t, ok, "claims cast")
		require.True(t, token.Valid, "JWT token valid")
		require.Equal(t, "gitlab-workhorse", claims["iss"], "JWT token issuer")

		w.Header().Set("Content-Type", api.ResponseContentType)
		_, err = w.Write([]byte(`{"hello":"world"}`))
		require.NoError(t, err, "write auth response")
	}))
	defer ts.Close()

	runPreAuthorizeHandler(
		t, ts, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		"",
		200, 201)
}
