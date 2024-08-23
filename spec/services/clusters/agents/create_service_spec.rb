# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::CreateService, feature_category: :deployment_management do
  subject(:service) { described_class.new(project, user, params) }

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  let(:name) { 'some-agent' }
  let(:params) { { name: name } }

  describe '#execute' do
    context 'without user permissions' do
      it 'returns errors when user does not have permissions' do
        response = service.execute

        expect(response.status).to eq(:error)
        expect(response.message).to eq('You have insufficient permissions to create a cluster agent for this project')
      end
    end

    context 'with user permissions' do
      before_all do
        project.add_maintainer(user)
      end

      it 'creates a new clusters_agent' do
        expect { service.execute }.to change { ::Clusters::Agent.count }.by(1)
      end

      it 'returns success status', :aggregate_failures do
        response = service.execute

        expect(response.status).to eq(:success)
        expect(response.message).to be_nil
      end

      it 'returns agent values', :aggregate_failures do
        new_agent = service.execute[:cluster_agent]

        expect(new_agent.name).to eq(name)
        expect(new_agent.created_by_user).to eq(user)
      end

      context 'with invalid name' do
        let(:name) { '@bad_agent_name!' }

        it 'generates an error message' do
          response = service.execute

          expect(response.status).to eq(:error)
          expect(response.message).to eq(
            ["Name can contain only lowercase letters, digits, and '-', but cannot start or end with '-'"]
          )
        end
      end
    end
  end
end
