# frozen_string_literal: true

RSpec.shared_examples_for "handle alias conflicts" do
  let(:slack_app_id) { 'A12345' }
  let(:slack_app_secret) { 'secret' }
  let(:oauth_code) { 'code' }
  let(:params) { { code: oauth_code } }
  let(:exchange_url) { described_class::SLACK_EXCHANGE_TOKEN_URL }

  let(:installation) { integration.slack_integration }
  let(:team_id) { 'T11111' }
  let(:team_name) { 'Team name' }
  let(:user_id) { 'U11111' }
  let(:bot_user_id) { 'U99999' }
  let(:bot_access_token) { 'token-XXXXX' }
  let(:response) do
    {
      ok: true,
      app_id: 'A12345',
      authed_user: { id: user_id },
      token_type: 'bot',
      access_token: bot_access_token,
      bot_user_id: bot_user_id,
      team: { id: team_id, name: team_name },
      enterprise: { is_enterprise_install: false },
      scope: 'chat:a,chat:b,chat:c'
    }
  end

  before do
    stub_application_setting(
      slack_app_enabled: true,
      slack_app_id: slack_app_id,
      slack_app_secret: slack_app_secret
    )

    query = {
      client_id: slack_app_id,
      client_secret: slack_app_secret,
      code: oauth_code,
      redirect_uri: redirect_url
    }

    stub_request(:get, exchange_url)
      .with(query: query)
      .to_return(body: response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  context 'when the alias is already taken' do
    before do
      create(:slack_integration, team_id: team_id, alias: installation_alias)
    end

    it 'creates the integration successfully and uses fallback_alias method value as the alternative alias' do
      result = service.execute

      expect(result).to be_success
      expect(installation.alias).to eq(service.send(:fallback_alias))
    end
  end
end
