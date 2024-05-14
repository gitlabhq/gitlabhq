# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::CreateService, feature_category: :webhooks do
  let_it_be(:current_user) { create(:user) }

  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:relation) { ProjectHook.none }
    let(:hook_params) { { url: 'https://example.com/hook', project_id: project.id } }

    subject(:webhook_created) { described_class.new(current_user) }

    context 'when creating a new hook' do
      it 'creates a new hook' do
        expect do
          response = webhook_created.execute(hook_params, relation)

          expect(response).to be_success
          expect(response[:async]).to eq(false)
        end.to change { ProjectHook.count }.by(1)
      end
    end

    context 'when the URL is invalid' do
      it 'returns an error response' do
        hook_params[:url] = 'invalid_url'

        response = webhook_created.execute(hook_params, relation)

        expect(response).not_to be_success
        expect(response[:message]).to eq("Invalid url given")
        expect(response[:http_status]).to eq(422)
      end
    end

    context 'when the branch filter is invalid' do
      let(:invalid_params) { hook_params.merge(push_events_branch_filter: 'bad branch name') }

      it 'returns an error response' do
        response = webhook_created.execute(invalid_params, relation)

        expect(response).not_to be_success
        expect(response[:message]).to eq("Invalid branch filter given")
        expect(response[:http_status]).to eq(422)
      end
    end

    context 'when the project is not provided' do
      let(:invalid_params) { hook_params.merge(project_id: nil) }

      it 'returns an error response for missing project' do
        response = webhook_created.execute(invalid_params, relation)

        expect(response).not_to be_success
        expect(response[:message]).to eq("Project can't be blank")
        expect(response[:http_status]).to eq(422)
      end
    end
  end
end
