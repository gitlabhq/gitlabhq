# frozen_string_literal: true

RSpec.shared_examples 'forbids quick actions for ai_workflows scope' do
  let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }
  let(:params) { {} }

  before do
    allow(Gitlab::Auth::ScopeValidator).to receive(:new).and_return(scope_validator)
  end

  context 'when quick actions are permitted' do
    let(:scope_validator) { instance_double(Gitlab::Auth::ScopeValidator, permit_quick_actions?: false) }

    it "returns 403 Forbidden when using quick actions" do
      send(method, api(url, oauth_access_token: oauth_token), params: params.merge(field => '/label ~bug'))
      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to eq('403 Forbidden - Quick actions cannot be used with AI workflows.')
    end
  end

  context 'when not permitted quick actions' do
    let(:scope_validator) { instance_double(Gitlab::Auth::ScopeValidator, permit_quick_actions?: true) }

    it "succeeds when not using quick actions" do
      send(method, api(url, oauth_access_token: oauth_token), params: params.merge(field => 'Regular content'))
      expect(response).to have_gitlab_http_status(success_status)
    end
  end
end
