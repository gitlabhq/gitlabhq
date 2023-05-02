# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackEvents::AppHomeOpenedService, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }

    let(:slack_workspace_id) { slack_installation.team_id }
    let(:slack_user_id) { 'U0123ABCDEF' }
    let(:api_url) { "#{Slack::API::BASE_URL}/views.publish" }
    let(:api_response) { { ok: true } }
    let(:params) do
      {
        team_id: slack_workspace_id,
        event: { user: slack_user_id },
        event_id: 'Ev03SA75UJKB'
      }
    end

    subject(:execute) { described_class.new(params).execute }

    before do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: api_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    shared_examples 'there is no bot token' do
      it 'does not call the Slack API, logs info, and returns a success response' do
        expect(Gitlab::IntegrationsLogger).to receive(:info).with(
          {
            slack_user_id: slack_user_id,
            slack_workspace_id: slack_workspace_id,
            message: 'SlackInstallation record has no bot token'
          }
        )

        is_expected.to be_success
      end
    end

    it 'calls the Slack API correctly and returns a success response' do
      mock_view = { type: 'home', blocks: [] }

      expect_next_instance_of(Slack::BlockKit::AppHomeOpened) do |ui|
        expect(ui).to receive(:build).and_return(mock_view)
      end

      is_expected.to be_success

      expect(WebMock).to have_requested(:post, api_url).with(
        body: {
          user_id: slack_user_id,
          view: mock_view
        },
        headers: {
          'Authorization' => "Bearer #{slack_installation.bot_access_token}",
          'Content-Type' => 'application/json; charset=utf-8'
        })
    end

    context 'when the slack installation is a legacy record' do
      let_it_be(:slack_installation) { create(:slack_integration, :legacy) }

      it_behaves_like 'there is no bot token'
    end

    context 'when the slack installation cannot be found' do
      let(:slack_workspace_id) { non_existing_record_id }

      it_behaves_like 'there is no bot token'
    end

    context 'when the Slack API call raises an HTTP exception' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED, 'error message')
      end

      it 'tracks the exception and returns an error response' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            Errno::ECONNREFUSED.new('HTTP exception when calling Slack API'),
            {
              slack_user_id: slack_user_id,
              slack_workspace_id: slack_workspace_id
            }
          )
        is_expected.to be_error
      end
    end

    context 'when the Slack API returns an error' do
      let(:api_response) { { ok: false, foo: 'bar' } }

      it 'tracks the exception and returns an error response' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            StandardError.new('Slack API returned an error'),
            {
              slack_user_id: slack_user_id,
              slack_workspace_id: slack_workspace_id,
              response: api_response.with_indifferent_access
            }
          )
        is_expected.to be_error
      end
    end
  end
end
