# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::CreateService, feature_category: :deployment_management do
  subject(:service) { described_class.new(project, user) }

  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }

  describe '#execute' do
    context 'without user permissions' do
      it 'returns errors when user does not have permissions' do
        expect(service.execute(name: 'missing-permissions')).to eq({
          status: :error,
          message: 'You have insufficient permissions to create a cluster agent for this project'
        })
      end
    end

    context 'with user permissions' do
      before do
        project.add_maintainer(user)
      end

      it 'creates a new clusters_agent' do
        expect { service.execute(name: 'with-user') }.to change { ::Clusters::Agent.count }.by(1)
      end

      it 'returns success status', :aggregate_failures do
        result = service.execute(name: 'success')

        expect(result[:status]).to eq(:success)
        expect(result[:message]).to be_nil
      end

      it 'returns agent values', :aggregate_failures do
        new_agent = service.execute(name: 'new-agent')[:cluster_agent]

        expect(new_agent.name).to eq('new-agent')
        expect(new_agent.created_by_user).to eq(user)
      end

      it 'generates an error message when name is invalid' do
        expect(service.execute(name: '@bad_agent_name!')).to eq({
          status: :error,
          message: ["Name can contain only lowercase letters, digits, and '-', but cannot start or end with '-'"]
        })
      end
    end
  end
end
