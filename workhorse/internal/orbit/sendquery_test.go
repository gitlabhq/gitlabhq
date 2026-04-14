package orbit

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	gkgpb "gitlab.com/gitlab-org/orbit/knowledge-graph/clients/gkgpb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

type mockGKGServer struct {
	gkgpb.UnimplementedKnowledgeGraphServiceServer
	handler func(stream grpc.BidiStreamingServer[gkgpb.ExecuteQueryMessage, gkgpb.ExecuteQueryMessage]) error
}

func (m *mockGKGServer) ExecuteQuery(stream grpc.BidiStreamingServer[gkgpb.ExecuteQueryMessage, gkgpb.ExecuteQueryMessage]) error {
	return m.handler(stream)
}

func startMockGKGServer(t *testing.T, handler func(stream grpc.BidiStreamingServer[gkgpb.ExecuteQueryMessage, gkgpb.ExecuteQueryMessage]) error) net.Listener {
	t.Helper()

	lis, err := net.Listen("tcp", "127.0.0.1:0")
	require.NoError(t, err)

	s := grpc.NewServer()
	gkgpb.RegisterKnowledgeGraphServiceServer(s, &mockGKGServer{handler: handler})

	go func() { _ = s.Serve(lis) }()
	t.Cleanup(func() {
		s.Stop()
	})

	return lis
}

func injectTestClient(t *testing.T, lis net.Listener, address string) {
	t.Helper()

	conn, err := grpc.NewClient(
		lis.Addr().String(),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	require.NoError(t, err)

	key := cacheKey{address: address}
	cache.Lock()
	cache.connections[key] = conn
	cache.Unlock()

	t.Cleanup(func() {
		cache.Lock()
		delete(cache.connections, key)
		cache.Unlock()
		conn.Close()
	})
}

func buildSendData(t *testing.T, params sendQueryParams) string {
	t.Helper()

	jsonBytes, err := json.Marshal(params)
	require.NoError(t, err)
	return "orbit-query:" + base64.URLEncoding.EncodeToString(jsonBytes)
}

func newTestAPI(t *testing.T, railsURL string) *api.API {
	t.Helper()

	testhelper.ConfigureSecret()

	u, err := url.Parse(railsURL)
	require.NoError(t, err)
	return api.NewAPI(u, "test-version", http.DefaultTransport)
}

func TestInjectHappyPath(t *testing.T) {
	const testAddress = "test-happy-path:50051"

	lis := startMockGKGServer(t, func(stream grpc.BidiStreamingServer[gkgpb.ExecuteQueryMessage, gkgpb.ExecuteQueryMessage]) error {
		msg, err := stream.Recv()
		if err != nil {
			return err
		}
		_ = msg.GetRequest()

		sendErr := stream.Send(&gkgpb.ExecuteQueryMessage{
			Content: &gkgpb.ExecuteQueryMessage_Redaction{
				Redaction: &gkgpb.RedactionExchange{
					Content: &gkgpb.RedactionExchange_Required{
						Required: &gkgpb.RedactionRequired{
							ResultId: "r1",
							Resources: []*gkgpb.ResourceToAuthorize{
								{
									ResourceType: "project",
									ResourceIds:  []int64{1, 2},
									Abilities:    []string{"read_project"},
								},
							},
						},
					},
				},
			},
		})
		if sendErr != nil {
			return sendErr
		}

		redactionMsg, err := stream.Recv()
		if err != nil {
			return err
		}
		_ = redactionMsg.GetRedaction().GetResponse()

		return stream.Send(&gkgpb.ExecuteQueryMessage{
			Content: &gkgpb.ExecuteQueryMessage_Result{
				Result: &gkgpb.ExecuteQueryResult{
					Content: &gkgpb.ExecuteQueryResult_ResultJson{
						ResultJson: `[{"id":1,"name":"test"}]`,
					},
					Metadata: &gkgpb.QueryMetadata{
						QueryType:       "traversal",
						RawQueryStrings: []string{"SELECT * FROM projects"},
						RowCount:        1,
					},
				},
			},
		})
	})
	injectTestClient(t, lis, testAddress)

	railsServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v4/internal/orbit/redaction" {
			t.Errorf("expected path /api/v4/internal/orbit/redaction, got %s", r.URL.Path)
			w.WriteHeader(http.StatusNotFound)
			return
		}

		if r.Header.Get("Private-Token") != "test-pat-token" {
			t.Errorf("expected auth header to be forwarded, got %q", r.Header.Get("Private-Token"))
		}

		var reqBody redactionRequest
		if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
			t.Errorf("failed to decode request body: %v", err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(redactionAPIResponse{
			Authorizations: []resourceAuth{
				{
					ResourceType: "project",
					Authorized:   map[string]bool{"1": true, "2": false},
				},
			},
		})
	}))
	defer railsServer.Close()

	myAPI := newTestAPI(t, railsServer.URL)
	sq := NewSendQuery(myAPI, "test-version")

	sendData := buildSendData(t, sendQueryParams{
		GkgServer: GkgServer{Address: testAddress},
		Query:     `{"match":{"name":"test"}}`,
		Format:    "raw",
	})

	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/v4/orbit/query", nil)
	req.Header.Set("Private-Token", "test-pat-token")
	sq.Inject(recorder, req, sendData)

	require.Equal(t, http.StatusOK, recorder.Code)

	var resp queryResponse
	require.NoError(t, json.NewDecoder(recorder.Body).Decode(&resp))
	require.Equal(t, "traversal", resp.QueryType)
	require.Equal(t, int32(1), resp.RowCount)
	require.NotEmpty(t, resp.Result)

	var resultRows []map[string]any
	require.NoError(t, json.Unmarshal(resp.Result, &resultRows))
	require.Len(t, resultRows, 1)
	require.Equal(t, "test", resultRows[0]["name"])
}

func TestInjectGrpcError(t *testing.T) {
	const testAddress = "test-grpc-error:50051"

	lis := startMockGKGServer(t, func(stream grpc.BidiStreamingServer[gkgpb.ExecuteQueryMessage, gkgpb.ExecuteQueryMessage]) error {
		if _, err := stream.Recv(); err != nil {
			return err
		}

		return stream.Send(&gkgpb.ExecuteQueryMessage{
			Content: &gkgpb.ExecuteQueryMessage_Error{
				Error: &gkgpb.ExecuteQueryError{
					Code:    "compile_error",
					Message: "invalid query syntax",
				},
			},
		})
	})
	injectTestClient(t, lis, testAddress)

	myAPI := newTestAPI(t, "http://unused.test")
	sq := NewSendQuery(myAPI, "test-version")

	sendData := buildSendData(t, sendQueryParams{
		GkgServer: GkgServer{Address: testAddress},
		Query:     `{"bad": }`,
	})

	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/v4/orbit/query", nil)
	sq.Inject(recorder, req, sendData)

	require.Equal(t, http.StatusBadRequest, recorder.Code)

	var errResp queryErrorResponse
	require.NoError(t, json.NewDecoder(recorder.Body).Decode(&errResp))
	require.Equal(t, "compile_error", errResp.Code)
	require.Equal(t, "invalid query syntax", errResp.Message)
}

func TestInjectRedactionFailure(t *testing.T) {
	const testAddress = "test-redaction-failure:50051"

	lis := startMockGKGServer(t, func(stream grpc.BidiStreamingServer[gkgpb.ExecuteQueryMessage, gkgpb.ExecuteQueryMessage]) error {
		if _, err := stream.Recv(); err != nil {
			return err
		}

		if err := stream.Send(&gkgpb.ExecuteQueryMessage{
			Content: &gkgpb.ExecuteQueryMessage_Redaction{
				Redaction: &gkgpb.RedactionExchange{
					Content: &gkgpb.RedactionExchange_Required{
						Required: &gkgpb.RedactionRequired{
							ResultId: "r1",
							Resources: []*gkgpb.ResourceToAuthorize{
								{
									ResourceType: "project",
									ResourceIds:  []int64{1},
									Abilities:    []string{"read_project"},
								},
							},
						},
					},
				},
			},
		}); err != nil {
			return err
		}

		// Wait for client to process the redaction failure; it will close the stream.
		_, _ = stream.Recv()
		return nil
	})
	injectTestClient(t, lis, testAddress)

	railsServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		io.WriteString(w, "internal server error")
	}))
	defer railsServer.Close()

	myAPI := newTestAPI(t, railsServer.URL)
	sq := NewSendQuery(myAPI, "test-version")

	sendData := buildSendData(t, sendQueryParams{
		GkgServer: GkgServer{Address: testAddress},
		Query:     `{"match":{}}`,
	})

	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/v4/orbit/query", nil)
	sq.Inject(recorder, req, sendData)

	require.Equal(t, http.StatusBadGateway, recorder.Code)
}

func TestInjectStreamTimeout(t *testing.T) {
	const testAddress = "test-stream-timeout:50051"

	lis := startMockGKGServer(t, func(stream grpc.BidiStreamingServer[gkgpb.ExecuteQueryMessage, gkgpb.ExecuteQueryMessage]) error {
		if _, err := stream.Recv(); err != nil {
			return err
		}
		// Delay longer than the context timeout to trigger gateway timeout.
		time.Sleep(5 * time.Second)
		return nil
	})
	injectTestClient(t, lis, testAddress)

	myAPI := newTestAPI(t, "http://unused.test")
	sq := NewSendQuery(myAPI, "test-version")

	sendData := buildSendData(t, sendQueryParams{
		GkgServer: GkgServer{Address: testAddress},
		Query:     `{"match":{}}`,
	})

	recorder := httptest.NewRecorder()
	// Use a short timeout so the test completes quickly.
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	req := httptest.NewRequest(http.MethodPost, "/api/v4/orbit/query", nil).WithContext(ctx)
	sq.Inject(recorder, req, sendData)

	require.Equal(t, http.StatusGatewayTimeout, recorder.Code)
}

func TestStripScheme(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"tls prefix", "tls://host:443", "host:443"},
		{"dns+tls prefix", "dns+tls:host:443", "dns:host:443"},
		{"tcp prefix", "tcp://host:50051", "host:50051"},
		{"no prefix", "host:50051", "host:50051"},
		{"dns+tls with slashes", "dns+tls://host:443", "dns://host:443"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.expected, stripScheme(tt.input))
		})
	}
}

func TestValidateMcpID(t *testing.T) {
	tests := []struct {
		name    string
		id      any
		wantErr bool
	}{
		{"nil is valid", nil, false},
		{"string is valid", "req-1", false},
		{"float64 is valid", float64(42), false},
		{"int as float64 is valid", float64(7), false},
		{"bool is invalid", true, true},
		{"slice is invalid", []int{1}, true},
		{"map is invalid", map[string]any{}, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateMcpID(tt.id)
			if tt.wantErr {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestBuildQueryResponse(t *testing.T) {
	t.Run("raw format with valid JSON", func(t *testing.T) {
		result := &gkgpb.ExecuteQueryResult{
			Content: &gkgpb.ExecuteQueryResult_ResultJson{
				ResultJson: `[{"id":1}]`,
			},
			Metadata: &gkgpb.QueryMetadata{
				QueryType: "traversal",
				RowCount:  5,
			},
		}

		resp := buildQueryResponse(result, gkgpb.ResponseFormat_RESPONSE_FORMAT_RAW)
		require.Equal(t, "traversal", resp.QueryType)
		require.Equal(t, int32(5), resp.RowCount)
		require.JSONEq(t, `[{"id":1}]`, string(resp.Result))
	})

	t.Run("raw format with invalid JSON falls back to quoted string", func(t *testing.T) {
		result := &gkgpb.ExecuteQueryResult{
			Content: &gkgpb.ExecuteQueryResult_ResultJson{
				ResultJson: "not valid json",
			},
		}

		resp := buildQueryResponse(result, gkgpb.ResponseFormat_RESPONSE_FORMAT_RAW)
		require.Equal(t, `"not valid json"`, string(resp.Result))
	})

	t.Run("LLM format returns formatted text as JSON string", func(t *testing.T) {
		result := &gkgpb.ExecuteQueryResult{
			Content: &gkgpb.ExecuteQueryResult_FormattedText{
				FormattedText: "compact text output",
			},
			Metadata: &gkgpb.QueryMetadata{
				QueryType: "search",
				RowCount:  3,
			},
		}

		resp := buildQueryResponse(result, gkgpb.ResponseFormat_RESPONSE_FORMAT_LLM)
		require.Equal(t, "search", resp.QueryType)
		require.Equal(t, int32(3), resp.RowCount)
		require.Equal(t, `"compact text output"`, string(resp.Result))
	})

	t.Run("nil metadata produces zero-value fields", func(t *testing.T) {
		result := &gkgpb.ExecuteQueryResult{
			Content: &gkgpb.ExecuteQueryResult_ResultJson{
				ResultJson: `{}`,
			},
		}

		resp := buildQueryResponse(result, gkgpb.ResponseFormat_RESPONSE_FORMAT_RAW)
		require.Empty(t, resp.QueryType)
		require.Equal(t, int32(0), resp.RowCount)
	})
}
