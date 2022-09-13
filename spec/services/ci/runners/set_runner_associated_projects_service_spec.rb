# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::SetRunnerAssociatedProjectsService, '#execute' do
  subject(:execute) { described_class.new(runner: runner, current_user: user, project_ids: project_ids).execute }

  let_it_be(:owner_project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:original_projects) { [owner_project, project2] }
  let_it_be(:runner) { create(:ci_runner, :project, projects: original_projects) }

  context 'without user' do
    let(:user) { nil }
    let(:project_ids) { [project2.id] }

    it 'does not call assign_to on runner and returns error response', :aggregate_failures do
      expect(runner).not_to receive(:assign_to)

      expect(execute).to be_error
      expect(execute.message).to eq('user not allowed to assign runner')
    end
  end

  context 'with unauthorized user' do
    let(:user) { build(:user) }
    let(:project_ids) { [project2.id] }

    it 'does not call assign_to on runner and returns error message' do
      expect(runner).not_to receive(:assign_to)

      expect(execute).to be_error
      expect(execute.message).to eq('user not allowed to assign runner')
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:user, :admin) }
    let(:project_ids) { [project3.id, project4.id] }
    let(:project3) { create(:project) }
    let(:project4) { create(:project) }

    context 'with successful requests' do
      it 'calls assign_to on runner and returns success response' do
        expect(execute).to be_success
        expect(runner.reload.projects.ids).to match_array([owner_project.id] + project_ids)
      end
    end

    context 'with failing assign_to requests' do
      it 'returns error response and rolls back transaction' do
        expect(runner).to receive(:assign_to).with(project4, user).once.and_return(false)

        expect(execute).to be_error
        expect(runner.reload.projects).to match_array(original_projects)
      end
    end

    context 'with failing destroy calls' do
      it 'returns error response and rolls back transaction' do
        allow_next_found_instance_of(Ci::RunnerProject) do |runner_project|
          allow(runner_project).to receive(:destroy).and_return(false)
        end

        expect(execute).to be_error
        expect(runner.reload.projects).to match_array(original_projects)
      end
    end
  end
end
