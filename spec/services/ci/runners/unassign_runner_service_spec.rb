# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UnassignRunnerService, '#execute', :aggregate_failures, feature_category: :runner do
  let_it_be(:owner_project) { create(:project) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [owner_project, other_project]) }

  let(:project_to_unassign) { other_project }
  let(:runner_project) { runner.runner_projects.find_by(project_id: project_to_unassign.id) }

  subject(:execute) { described_class.new(runner_project, user).execute }

  context 'without user' do
    let(:user) { nil }

    it 'does not destroy runner_project' do
      expect(runner_project).not_to receive(:destroy)
      expect { execute }.not_to change { runner.runner_projects.count }.from(2)

      expect(execute).to be_error
      expect(execute.message).to eq('User not allowed to assign runner')
    end
  end

  context 'with unauthorized user' do
    let(:user) { create(:user, developer_of: other_project) }

    it 'returns error and does not destroy runner_project' do
      expect(runner_project).not_to receive(:destroy)

      expect(execute).to be_error
      expect(execute.message).to eq('User not allowed to assign runner')
    end
  end

  context 'with project maintainer' do
    let(:user) { create(:user, maintainer_of: other_project) }

    it { is_expected.to be_success }
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:admin) }

    it { is_expected.to be_success }

    context 'when unassigning from owner project' do
      let(:project_to_unassign) { owner_project }

      it 'returns error response' do
        expect(execute).to be_error
        expect(execute.message).to eq(
          'You cannot unassign a runner from the owner project. Delete the runner instead')
      end
    end

    context 'with destroy returning false' do
      it 'returns error response' do
        expect(runner_project).to receive(:destroy).once.and_return(false)

        expect(execute).to be_error
        expect(execute.message).to eq('Failed to destroy runner project')
      end
    end
  end
end
