# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::IncidentManagement::IncidentModalOpenedService,
  feature_category: :incident_management do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user, developer_of: project) }
    let_it_be(:trigger_id) { '12345.98765.abcd2358fdea' }

    let(:slack_workspace_id) { slack_installation.team_id }
    let(:response_url) { 'https://api.slack.com/id/123' }
    let(:api_url) { "#{Slack::API::BASE_URL}/views.open" }
    let(:mock_modal) { { type: 'modal', blocks: [] } }
    let(:params) do
      {
        team_id: slack_workspace_id,
        response_url: response_url,
        trigger_id: trigger_id
      }
    end

    before do
      response = {
        id: '123',
        state: {
          values: {
            project_and_severity_selector: {
              incident_management_project: {
                selected_option: {
                  value: project.id.to_s
                }
              }
            }
          }
        }
      }
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: Gitlab::Json.dump({ ok: true, view: response }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    subject { described_class.new(slack_installation, user, params) }

    context 'when triggered' do
      it 'opens the modal' do
        expect_next_instance_of(Slack::BlockKit::IncidentManagement::IncidentModalOpened) do |ui|
          expect(ui).to receive(:build).and_return(mock_modal)
        end

        expect(Rails.cache).to receive(:write).with(
          'slack:incident_modal_opened:123', project.id.to_s, { expires_in: 5.minutes })

        response = subject.execute

        expect(WebMock).to have_requested(:post, api_url).with(
          body: {
            trigger_id: trigger_id,
            view: mock_modal
          },
          headers: {
            'Authorization' => "Bearer #{slack_installation.bot_access_token}",
            'Content-Type' => 'application/json; charset=utf-8'
          })

        expect(response.message).to eq('Please complete the incident creation form.')
      end
    end

    context 'when there are no projects with slack integration' do
      let(:params) do
        {
          team_id: 'some_random_id',
          response_url: response_url,
          trigger_id: trigger_id
        }
      end

      let(:user) { create(:user) }

      it 'does not open the modal' do
        response = subject.execute

        expect(Rails.cache).not_to receive(:write)
        expect(response.message).to be('You do not have access to any projects for creating incidents.')
      end
    end

    context 'when Slack API call raises an HTTP exception' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED, 'error message')
      end

      it 'tracks the exception and returns an error response' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            Errno::ECONNREFUSED.new('HTTP exception when calling Slack API'),
            {
              slack_workspace_id: slack_workspace_id
            }
          )

        expect(Rails.cache).not_to receive(:write)
        expect(subject.execute).to be_error
      end
    end

    context 'when api returns an error' do
      before do
        stub_request(:post, api_url)
          .to_return(
            status: 404,
            body: Gitlab::Json.dump({ ok: false }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error when called' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            StandardError.new('Something went wrong while opening the incident form.'),
            {
              response: { "ok" => false },
              slack_workspace_id: slack_workspace_id,
              slack_user_id: slack_installation.user_id
            }
          )

        expect(Rails.cache).not_to receive(:write)
        response = subject.execute

        expect(response.message).to eq('Something went wrong while opening the incident form.')
      end
    end
  end
end
