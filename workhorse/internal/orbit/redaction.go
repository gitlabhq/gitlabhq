package orbit

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	gkgpb "gitlab.com/gitlab-org/orbit/knowledge-graph/clients/gkgpb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
)

const redactionEndpointPath = "/api/v4/internal/orbit/redaction"

type redactionRequest struct {
	Resources []redactionResource `json:"resources"`
}

type redactionResource struct {
	ResourceType string  `json:"resource_type"`
	ResourceIDs  []int64 `json:"resource_ids"`
	Ability      string  `json:"ability"`
}

type redactionAPIResponse struct {
	Authorizations []resourceAuth `json:"authorizations"`
}

type resourceAuth struct {
	ResourceType string          `json:"resource_type"`
	Authorized   map[string]bool `json:"authorized"`
}

var authHeaders = []string{"Authorization", "Private-Token", "Cookie", "X-Csrf-Token"}

func (sq *SendQuery) callRedaction(ctx context.Context, originalReq *http.Request, required *gkgpb.RedactionRequired) (*gkgpb.RedactionResponse, error) {
	reqBody := buildRedactionRequest(required)

	body, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("marshal redaction request: %v", err)
	}

	redactURL := *sq.api.URL
	redactURL.Path = redactionEndpointPath

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, redactURL.String(), bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("create redaction request: %v", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("User-Agent", "GitLab-Workhorse")
	for _, h := range authHeaders {
		if v := originalReq.Header.Get(h); v != "" {
			httpReq.Header.Set(h, v)
		}
	}

	signingTripper := secret.NewRoundTripper(sq.api.Client.Transport, sq.version)
	httpResp, err := signingTripper.RoundTrip(httpReq)
	if err != nil {
		return nil, fmt.Errorf("redaction request: %v", err)
	}
	defer func() { _ = httpResp.Body.Close() }()

	if httpResp.StatusCode < 200 || httpResp.StatusCode >= 300 {
		return nil, fmt.Errorf("redaction response status: %s", httpResp.Status)
	}

	var apiResp redactionAPIResponse
	if err := json.NewDecoder(httpResp.Body).Decode(&apiResp); err != nil {
		return nil, fmt.Errorf("decode redaction response: %v", err)
	}

	return toRedactionProto(required.GetResultId(), apiResp), nil
}

func buildRedactionRequest(required *gkgpb.RedactionRequired) redactionRequest {
	req := redactionRequest{}
	for _, res := range required.GetResources() {
		for _, ability := range res.GetAbilities() {
			req.Resources = append(req.Resources, redactionResource{
				ResourceType: res.GetResourceType(),
				ResourceIDs:  res.GetResourceIds(),
				Ability:      ability,
			})
		}
	}
	return req
}

func toRedactionProto(resultID string, apiResp redactionAPIResponse) *gkgpb.RedactionResponse {
	protoResp := &gkgpb.RedactionResponse{ResultId: resultID}
	for _, auth := range apiResp.Authorizations {
		authorized := make(map[int64]bool, len(auth.Authorized))
		for idStr, allowed := range auth.Authorized {
			id, err := strconv.ParseInt(idStr, 10, 64)
			if err != nil {
				log.WithFields(log.Fields{"resource_type": auth.ResourceType, "id_string": idStr}).
					WithError(fmt.Errorf("orbit.redaction: failed to parse resource ID")).Error()
				continue
			}
			authorized[id] = allowed
		}
		protoResp.Authorizations = append(protoResp.Authorizations, &gkgpb.ResourceAuthorization{
			ResourceType: auth.ResourceType,
			Authorized:   authorized,
		})
	}
	return protoResp
}
