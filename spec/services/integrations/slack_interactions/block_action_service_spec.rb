# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::BlockActionService, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }

    let(:params) do
      {
        view: {
          team_id: slack_installation.team_id
        },
        actions: [{
          action_id: action_id
        }]
      }
    end

    subject(:execute) { described_class.new(params).execute }

    context 'when action_id is incident_management_project' do
      let(:action_id) { 'incident_management_project' }

      it 'executes the correct handler' do
        project_handler = described_class::ALLOWED_UPDATES_HANDLERS['incident_management_project']

        expect_next_instance_of(project_handler, params, params[:actions].first) do |handler|
          expect(handler).to receive(:execute).and_return(ServiceResponse.success)
        end

        execute
      end
    end

    context 'when action_id is not known' do
      let(:action_id) { 'random' }

      it 'does not execute the handlers' do
        described_class::ALLOWED_UPDATES_HANDLERS.each_value do |handler_class|
          expect(handler_class).not_to receive(:new)
        end

        execute
      end
    end
  end
end
