# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::DeleteUrlConfigurationService, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be_with_reload(:agent) { create(:cluster_agent, is_receptive: true) }
    let_it_be_with_reload(:project) { agent.project }
    let_it_be_with_reload(:user) { create(:user) }

    let!(:url_configuration) { create(:cluster_agent_url_configuration, agent: agent, created_by_user: user) }

    subject(:service) { described_class.new(agent: agent, current_user: user, url_configuration: url_configuration) }

    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      context 'without user permissions' do
        it 'fails to delete when the user has no permissions', :aggregate_failures do
          response = service.execute

          expect(response.status).to eq(:error)
          expect(response.message).to eq('You have insufficient permissions to delete this agent url configuration')

          expect { url_configuration.reload }.not_to raise_error
        end
      end

      context 'with user permissions' do
        before_all do
          project.add_maintainer(user)
        end

        it 'deletes a agent url configuration', :aggregate_failures do
          expect { service.execute }.to change { ::Clusters::Agents::UrlConfiguration.count }.by(-1)
          expect { url_configuration.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(agent.is_receptive).to be(false)
        end

        context 'when destroy fails' do
          before do
            allow(url_configuration).to receive(:destroy) do
              url_configuration.errors.add(:test_attr, 'test error')

              false
            end
          end

          it 'returns an error' do
            response = service.execute

            expect(response.status).to eq(:error)
            expect(response.message).to eq(['Test attr test error'])
          end
        end
      end
    end

    context 'when receptive agents are disabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response.status).to eq(:error)
        expect(response.message).to eq('Receptive agents are disabled for this GitLab instance')
      end
    end
  end
end
