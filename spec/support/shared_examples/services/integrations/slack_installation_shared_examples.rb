# frozen_string_literal: true

RSpec.shared_examples_for Integrations::SlackInstallation::BaseService do
  let(:slack_app_id) { 'A12345' }
  let(:slack_app_secret) { 'secret' }
  let(:oauth_code) { 'code' }
  let(:params) { { code: oauth_code } }
  let(:exchange_url) { described_class::SLACK_EXCHANGE_TOKEN_URL }
  let(:installation) { integration.slack_integration }

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

  shared_examples 'error response' do |message:|
    it 'returns error result with message' do
      result = service.execute

      expect(result).to be_error
      expect(result.message).to eq(message)
      expect(integration).to be_nil
    end
  end

  context 'when Slack responds with an error' do
    let(:response) do
      {
        ok: false,
        error: 'something is wrong'
      }
    end

    it_behaves_like 'error response', message: 'Error exchanging OAuth token with Slack: something is wrong'
  end

  context 'when HTTP error occurs when exchanging token' do
    let(:response) { {} }

    before do
      allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED.new('error'))
    end

    it_behaves_like 'error response', message: 'Error exchanging OAuth token with Slack'

    it 'tracks the error' do
      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(Errno::ECONNREFUSED.new('Error exchanging OAuth token with Slack'), kind_of(Hash))

      service.execute
    end
  end

  context 'when slack_app_enabled is not set' do
    before do
      stub_application_setting(slack_app_enabled: false)
    end

    let(:response) { {} }

    it_behaves_like 'error response', message: 'Slack app not enabled on GitLab instance'
  end

  context 'when user is unauthorized' do
    let_it_be(:user) { create(:user) }

    let(:response) { {} }

    it_behaves_like 'error response', message: 'Unauthorized'
  end

  context 'when Slack responds with an access token' do
    let_it_be(:team_id) { 'T11111' }
    let_it_be(:team_name) { 'Team name' }
    let_it_be(:user_id) { 'U11111' }
    let_it_be(:bot_user_id) { 'U99999' }
    let_it_be(:bot_access_token) { 'token-XXXXX' }

    let(:response) do
      {
        ok: true,
        app_id: 'A12345',
        authed_user: { id: user_id },
        token_type: 'bot',
        access_token: bot_access_token,
        bot_user_id: bot_user_id,
        team: { id: team_id, name: 'Team name' },
        enterprise: { is_enterprise_install: false },
        scope: 'chat:a,chat:b,chat:c'
      }
    end

    shared_examples 'success response' do
      it 'returns success result and creates all needed records' do
        result = service.execute

        expect(result).to be_success
        expect(integration.reload).to be_present
        expect(installation.reload).to be_present
        expect(installation).to have_attributes(
          integration_id: integration.id,
          team_id: team_id,
          team_name: team_name,
          alias: installation_alias,
          user_id: user_id,
          bot_user_id: bot_user_id,
          bot_access_token: bot_access_token,
          authorized_scope_names: contain_exactly('chat:a', 'chat:b', 'chat:c')
        )
      end
    end

    it_behaves_like 'success response'

    context 'when integration record already exists' do
      before do
        create_gitlab_slack_application_integration!
      end

      it_behaves_like 'success response'

      context 'when installation record already exists' do
        before do
          integration.create_slack_integration!(
            team_id: 'old value',
            team_name: 'old value',
            alias: 'old value',
            user_id: 'old value',
            bot_user_id: 'old value',
            bot_access_token: 'old value'
          )
        end

        it_behaves_like 'success response'
      end
    end

    it 'handles propagation correctly' do
      allow(PropagateIntegrationWorker).to receive(:perform_async)

      service.execute

      if enqueues_propagation_worker
        expect(PropagateIntegrationWorker).to have_received(:perform_async).with(integration.id)
      else
        expect(PropagateIntegrationWorker).not_to have_received(:perform_async)
      end
    end

    context 'when the team has other Slack installation records' do
      let_it_be_with_reload(:other_installation) { create(:slack_integration, team_id: team_id) }
      let_it_be_with_reload(:other_legacy_installation) { create(:slack_integration, :legacy, team_id: team_id) }
      let_it_be_with_reload(:legacy_installation_for_other_team) { create(:slack_integration, :legacy) }

      it_behaves_like 'success response'

      it 'updates related legacy records' do
        travel_to(1.minute.from_now) do
          expected_attributes = {
            'user_id' => user_id,
            'bot_user_id' => bot_user_id,
            'bot_access_token' => bot_access_token,
            'updated_at' => Time.current,
            'authorized_scope_names' => %w[chat:a chat:b chat:c]
          }

          service.execute

          expect(other_installation).to have_attributes(expected_attributes)
          expect(other_legacy_installation).to have_attributes(expected_attributes)
          expect(legacy_installation_for_other_team).not_to have_attributes(expected_attributes)
        end
      end
    end
  end
end
