package orbit

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	gkgpb "gitlab.com/gitlab-org/orbit/knowledge-graph/clients/gkgpb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

const defaultStreamingTimeout = 30 * time.Second
const maxStreamingTimeout = 120 * time.Second

// SendQuery is a senddata.Injecter that handles GKG graph queries via gRPC.
type SendQuery struct {
	senddata.Prefix
	api     *api.API
	version string
}

// NewSendQuery returns a SendQuery injecter that uses the given API for redaction callbacks.
func NewSendQuery(myAPI *api.API, version string) *SendQuery {
	return &SendQuery{
		Prefix:  "orbit-query:",
		api:     myAPI,
		version: version,
	}
}

type sendQueryParams struct {
	GkgServer      GkgServer `json:"GkgServer"`
	Query          string    `json:"Query"`
	Format         string    `json:"Format"`
	TimeoutSeconds int       `json:"TimeoutSeconds,omitempty"`
	McpID          any       `json:"McpId,omitempty"`
}

type queryResponse struct {
	Result          json.RawMessage `json:"result,omitempty"`
	QueryType       string          `json:"query_type"`
	RawQueryStrings []string        `json:"raw_query_strings,omitempty"`
	RowCount        int32           `json:"row_count"`
}

type queryErrorResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type mcpResponse struct {
	JSONRPC string `json:"jsonrpc"`
	Result  any    `json:"result,omitempty"`
	Error   any    `json:"error,omitempty"`
	ID      any    `json:"id"`
}

type mcpToolResult struct {
	Content []mcpContent `json:"content"`
	IsError bool         `json:"isError"`
}

type mcpContent struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

// Inject handles the orbit-query: SendData prefix by opening a gRPC stream to the GKG server.
func (sq *SendQuery) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params sendQueryParams
	if err := sq.Unpack(&params, sendData); err != nil {
		fail.Request(w, r, fmt.Errorf("orbit.SendQuery: unpack sendData: %v", err))
		return
	}

	if err := validateMcpID(params.McpID); err != nil {
		fail.Request(w, r, err)
		return
	}

	timeout := defaultStreamingTimeout
	if params.TimeoutSeconds > 0 {
		timeout = min(time.Duration(params.TimeoutSeconds)*time.Second, maxStreamingTimeout)
	}
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	client, err := getClient(params.GkgServer)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("orbit.SendQuery: create client: %v", err), fail.WithStatus(http.StatusServiceUnavailable))
		return
	}

	ctx = buildOutgoingContext(ctx, params.GkgServer)

	stream, err := client.ExecuteQuery(ctx)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("orbit.SendQuery: open stream: %v", err), fail.WithStatus(http.StatusBadGateway))
		return
	}
	defer func() { _ = stream.CloseSend() }()

	format := gkgpb.ResponseFormat_RESPONSE_FORMAT_RAW
	if params.Format == "llm" {
		format = gkgpb.ResponseFormat_RESPONSE_FORMAT_LLM
	}

	initialMsg := &gkgpb.ExecuteQueryMessage{
		Content: &gkgpb.ExecuteQueryMessage_Request{
			Request: &gkgpb.ExecuteQueryRequest{
				Query:     params.Query,
				Format:    format,
				QueryType: gkgpb.QueryType_QUERY_TYPE_JSON,
			},
		},
	}

	if err := stream.Send(initialMsg); err != nil {
		fail.Request(w, r, fmt.Errorf("orbit.SendQuery: send request: %v", err), fail.WithStatus(http.StatusBadGateway))
		return
	}

	sq.recvLoop(ctx, w, r, stream, params, format)
}

const maxStreamMessages = 10

func (sq *SendQuery) recvLoop(
	ctx context.Context,
	w http.ResponseWriter, r *http.Request,
	stream gkgpb.KnowledgeGraphService_ExecuteQueryClient,
	params sendQueryParams,
	format gkgpb.ResponseFormat,
) {
	for range maxStreamMessages {
		msg, err := stream.Recv()
		if err != nil {
			handleRecvError(ctx, w, r, err)
			return
		}

		switch c := msg.GetContent().(type) {
		case *gkgpb.ExecuteQueryMessage_Redaction:
			if err := sq.handleRedaction(ctx, r, stream, c.Redaction); err != nil {
				fail.Request(w, r, err, fail.WithStatus(http.StatusBadGateway))
				return
			}
		case *gkgpb.ExecuteQueryMessage_Result:
			writeResultResponse(w, r, c.Result, format, params.McpID)
			return
		case *gkgpb.ExecuteQueryMessage_Error:
			writeErrorResponse(w, r, c.Error, params.McpID)
			return
		}
	}

	fail.Request(w, r, fmt.Errorf("orbit.SendQuery: exceeded %d stream messages without result", maxStreamMessages),
		fail.WithStatus(http.StatusBadGateway))
}

func handleRecvError(ctx context.Context, w http.ResponseWriter, r *http.Request, err error) {
	if err == io.EOF {
		fail.Request(w, r, fmt.Errorf("orbit.SendQuery: stream ended without result"), fail.WithStatus(http.StatusBadGateway))
		return
	}
	if isContextDone(ctx, err) {
		fail.Request(w, r, fmt.Errorf("orbit.SendQuery: %v", err), fail.WithStatus(http.StatusGatewayTimeout))
		return
	}
	log.WithRequest(r).WithError(fmt.Errorf("orbit.SendQuery: stream recv: %v", err)).Error()
	fail.Request(w, r, fmt.Errorf("orbit.SendQuery: stream error"), fail.WithStatus(http.StatusBadGateway))
}

// isContextDone returns true when the recv error was caused by the context
// being done (deadline exceeded or canceled). It checks both the local
// context and the gRPC status code for DeadlineExceeded so the detection
// is race-free: gRPC may return the error before the child context's
// Err() is set.
func isContextDone(ctx context.Context, err error) bool {
	if ctx.Err() != nil {
		return true
	}
	if st, ok := status.FromError(err); ok {
		return st.Code() == codes.DeadlineExceeded
	}
	return false
}

func (sq *SendQuery) handleRedaction(
	ctx context.Context,
	originalReq *http.Request,
	stream gkgpb.KnowledgeGraphService_ExecuteQueryClient,
	exchange *gkgpb.RedactionExchange,
) error {
	required := exchange.GetRequired()
	if required == nil {
		return nil
	}

	redactionResp, err := sq.callRedaction(ctx, originalReq, required)
	if err != nil {
		return fmt.Errorf("orbit.SendQuery: redaction callback: %v", err)
	}

	respMsg := &gkgpb.ExecuteQueryMessage{
		Content: &gkgpb.ExecuteQueryMessage_Redaction{
			Redaction: &gkgpb.RedactionExchange{
				Content: &gkgpb.RedactionExchange_Response{
					Response: redactionResp,
				},
			},
		},
	}
	if err := stream.Send(respMsg); err != nil {
		return fmt.Errorf("orbit.SendQuery: send redaction response: %v", err)
	}
	return nil
}

func writeResultResponse(w http.ResponseWriter, r *http.Request, result *gkgpb.ExecuteQueryResult, format gkgpb.ResponseFormat, mcpID any) {
	if format == gkgpb.ResponseFormat_RESPONSE_FORMAT_LLM {
		writeLLMResultResponse(w, r, result, mcpID)
		return
	}

	resp := buildQueryResponse(result, format)

	w.Header().Del("Content-Length")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	var out any = resp
	if mcpID != nil {
		resultJSON, err := json.Marshal(resp)
		if err != nil {
			log.WithRequest(r).WithError(fmt.Errorf("orbit.SendQuery: marshal MCP result: %v", err)).Error()
		}
		out = wrapMCPSuccess(resultJSON, mcpID)
	}
	if err := json.NewEncoder(w).Encode(out); err != nil {
		log.WithRequest(r).WithError(fmt.Errorf("orbit.SendQuery: write response: %v", err)).Error()
	}
}

// writeLLMResultResponse writes the raw goon body directly: text/plain for
// REST callers, MCP text content for MCP callers. The JSON envelope is skipped
// because goon is not JSON; wrapping it would escape every newline.
func writeLLMResultResponse(w http.ResponseWriter, r *http.Request, result *gkgpb.ExecuteQueryResult, mcpID any) {
	body := result.GetFormattedText()

	w.Header().Del("Content-Length")
	if mcpID != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		out := mcpResponse{
			JSONRPC: "2.0",
			Result: mcpToolResult{
				Content: []mcpContent{{Type: "text", Text: body}},
				IsError: false,
			},
			ID: mcpID,
		}
		if err := json.NewEncoder(w).Encode(out); err != nil {
			log.WithRequest(r).WithError(fmt.Errorf("orbit.SendQuery: write LLM MCP response: %v", err)).Error()
		}
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	if _, err := io.WriteString(w, body); err != nil {
		log.WithRequest(r).WithError(fmt.Errorf("orbit.SendQuery: write LLM response: %v", err)).Error()
	}
}

func writeErrorResponse(w http.ResponseWriter, r *http.Request, qErr *gkgpb.ExecuteQueryError, mcpID any) {
	w.Header().Del("Content-Length")
	w.Header().Set("Content-Type", "application/json")

	var err error
	if mcpID != nil {
		w.WriteHeader(http.StatusOK)
		err = json.NewEncoder(w).Encode(mcpResponse{
			JSONRPC: "2.0",
			Result: mcpToolResult{
				Content: []mcpContent{{Type: "text", Text: qErr.GetMessage()}},
				IsError: true,
			},
			ID: mcpID,
		})
	} else {
		w.WriteHeader(gkgErrorToHTTPStatus(qErr.GetCode()))
		err = json.NewEncoder(w).Encode(queryErrorResponse{
			Code:    qErr.GetCode(),
			Message: qErr.GetMessage(),
		})
	}
	if err != nil {
		log.WithRequest(r).WithError(fmt.Errorf("orbit.SendQuery: write error response: %v", err)).Error()
	}
}

func wrapMCPSuccess(resultJSON []byte, mcpID any) mcpResponse {
	return mcpResponse{
		JSONRPC: "2.0",
		Result: mcpToolResult{
			Content: []mcpContent{{Type: "text", Text: string(resultJSON)}},
			IsError: false,
		},
		ID: mcpID,
	}
}

func buildQueryResponse(result *gkgpb.ExecuteQueryResult, format gkgpb.ResponseFormat) queryResponse {
	var resp queryResponse

	if md := result.GetMetadata(); md != nil {
		resp.QueryType = md.GetQueryType()
		resp.RawQueryStrings = md.GetRawQueryStrings()
		resp.RowCount = md.GetRowCount()
	}

	if format == gkgpb.ResponseFormat_RESPONSE_FORMAT_LLM {
		// LLM responses are written by writeLLMResultResponse with no envelope.
		// Leave Result nil; callers should not consume it for LLM format.
		return resp
	}

	raw := result.GetResultJson()
	if json.Valid([]byte(raw)) {
		resp.Result = json.RawMessage(raw)
	} else {
		resp.Result, _ = json.Marshal(raw)
	}

	return resp
}

func validateMcpID(id any) error {
	if id == nil {
		return nil
	}
	switch id.(type) {
	case string, float64:
		return nil
	default:
		return fmt.Errorf("orbit.SendQuery: invalid McpId type %T (must be string, number, or null)", id)
	}
}

func gkgErrorToHTTPStatus(code string) int {
	switch code {
	case "compile_error", "validation_error":
		return http.StatusBadRequest
	case "execution_error", "internal_error":
		return http.StatusBadGateway
	case "timeout":
		return http.StatusGatewayTimeout
	default:
		return http.StatusBadRequest
	}
}

// buildOutgoingContext attaches per-call gRPC metadata to ctx from the
// generic Headers map. All entries are forwarded verbatim; callers are
// responsible for populating the map with the correct header names and
// values (e.g. "authorization", "x-gitlab-enabled-feature-flags", …).
func buildOutgoingContext(ctx context.Context, server GkgServer) context.Context {
	if len(server.Headers) == 0 {
		return ctx
	}
	var pairs []string
	for k, v := range server.Headers {
		pairs = append(pairs, k, v)
	}
	return metadata.NewOutgoingContext(ctx, metadata.Pairs(pairs...))
}
