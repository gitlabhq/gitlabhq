# frozen_string_literal: true

RSpec.shared_examples 'forbids quick actions for ai_workflows scope' do
  let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }
  let(:params) { {} }
  # Status for a payload that is only an allowed quick action. Where the action is the
  # whole payload (e.g. a note body) nothing is persisted and the API returns 202 Accepted.
  let(:quick_action_success_status) { success_status }

  before do
    allow(Gitlab::Auth::ScopeValidator).to receive(:new).and_return(scope_validator)
  end

  context 'when quick actions are not permitted (ai_workflows scope)' do
    let(:scope_validator) { instance_double(Gitlab::Auth::ScopeValidator, permit_quick_actions?: false) }

    it "returns 403 Forbidden when using blocked quick actions" do
      send(method, api(url, oauth_access_token: oauth_token), params: params.merge(field => '/close'))
      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to match(/403 Forbidden - Quick actions .* cannot be used with AI workflows\./)
    end

    it "succeeds when using allowed quick actions" do
      send(method, api(url, oauth_access_token: oauth_token), params: params.merge(field => '/label ~bug'))
      expect(response).to have_gitlab_http_status(quick_action_success_status)
    end
  end

  context 'when quick actions are permitted' do
    let(:scope_validator) { instance_double(Gitlab::Auth::ScopeValidator, permit_quick_actions?: true) }

    it "succeeds when not using quick actions" do
      send(method, api(url, oauth_access_token: oauth_token), params: params.merge(field => 'Regular content'))
      expect(response).to have_gitlab_http_status(success_status)
    end
  end
end

# `oauth_token` is defined outside the context so a block passed to `it_behaves_like`
# can add payload assertions that reuse it.
RSpec.shared_examples 'allows access with the ai_workflows scope' do |status = :ok|
  let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

  context 'when authenticated with a token that has the ai_workflows scope' do
    it "returns #{status}" do
      api_request

      expect(response).to have_gitlab_http_status(status)
    end
  end
end

RSpec.shared_examples 'denies access with the ai_workflows scope' do
  let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

  context 'when authenticated with a token that has the ai_workflows scope' do
    it 'returns 403 insufficient_scope' do
      api_request

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['error']).to eq('insufficient_scope')
    end
  end
end
