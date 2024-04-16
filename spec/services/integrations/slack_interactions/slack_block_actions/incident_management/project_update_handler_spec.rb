# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::SlackBlockActions::IncidentManagement::ProjectUpdateHandler,
  feature_category: :incident_management do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }
    let_it_be(:old_project) { create(:project) }
    let_it_be(:new_project) { create(:project) }
    let_it_be(:user) { create(:user, developer_of: [old_project, new_project]) }
    let_it_be(:chat_name) { create(:chat_name, user: user) }
    let_it_be(:api_url) { "#{Slack::API::BASE_URL}/views.update" }

    let(:block) do
      {
        block_id: 'incident_description',
        element: {
          initial_value: ''
        }
      }
    end

    let(:view) do
      {
        id: 'V04EQH1SP27',
        team_id: slack_installation.team_id,
        blocks: [block]
      }
    end

    let(:action) do
      {
        selected_option: {
          value: new_project.id.to_s
        }
      }
    end

    let(:params) do
      {
        view: view,
        user: {
          id: slack_installation.user_id
        }
      }
    end

    before do
      allow_next_instance_of(ChatNames::FindUserService) do |user_service|
        allow(user_service).to receive(:execute).and_return(chat_name)
      end

      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: Gitlab::Json.dump({ ok: true }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    shared_examples 'does not make api call' do
      it 'does not make the api call and returns nil' do
        expect(Rails.cache).to receive(:read).and_return(project.id.to_s)
        expect(Rails.cache).not_to receive(:write)

        expect(execute).to be_nil
        expect(WebMock).not_to have_requested(:post, api_url)
      end
    end

    subject(:execute) { described_class.new(params, action).execute }

    context 'when project is updated' do
      it 'returns success response and updates cache' do
        expect(Rails.cache).to receive(:read).and_return(old_project.id.to_s)
        expect(Rails.cache).to receive(:write).with(
          "slack:incident_modal_opened:#{view[:id]}",
          new_project.id.to_s,
          expires_in: 5.minutes
        )

        expect(execute.message).to eq('Modal updated')

        updated_block = block.dup
        updated_block[:block_id] = new_project.id.to_s
        view[:blocks] = [updated_block]

        expect(WebMock).to have_requested(:post, api_url).with(
          body: {
            view_id: view[:id],
            view: view.except!(:team_id, :id)
          },
          headers: {
            'Authorization' => "Bearer #{slack_installation.bot_access_token}",
            'Content-Type' => 'application/json; charset=utf-8'
          })
      end
    end

    context 'when project is unchanged' do
      it_behaves_like 'does not make api call' do
        let(:project) { new_project }
      end
    end

    context 'when user does not have permission to read a project' do
      it_behaves_like 'does not make api call' do
        let(:project) { create(:project) }
      end
    end

    context 'when api response is not ok' do
      before do
        stub_request(:post, api_url)
          .to_return(
            status: 404,
            body: Gitlab::Json.dump({ ok: false }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error response' do
        expect(Rails.cache).to receive(:read).and_return(old_project.id.to_s)
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            StandardError.new('Something went wrong while updating the modal.'),
            {
              response: { "ok" => false },
              slack_workspace_id: slack_installation.team_id,
              slack_user_id: slack_installation.user_id
            }
          )

        expect(execute.message).to eq('Something went wrong while updating the modal.')
      end
    end

    context 'when Slack API call raises an HTTP exception' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED, 'error message')
      end

      it 'tracks the exception and returns an error message' do
        expect(Rails.cache).to receive(:read).and_return(old_project.id.to_s)
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            Errno::ECONNREFUSED.new('HTTP exception when calling Slack API'),
            {
              slack_workspace_id: slack_installation.team_id
            }
          )

        expect(execute).to be_error
      end
    end
  end
end
