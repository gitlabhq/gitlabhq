# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::SetRunnerAssociatedProjectsService, '#execute', feature_category: :runner_fleet do
  subject(:execute) { described_class.new(runner: runner, current_user: user, project_ids: project_ids).execute }

  let_it_be(:owner_project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:original_projects) { [owner_project, project2] }

  let(:runner) { create(:ci_runner, :project, projects: original_projects) }

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
    let_it_be(:user) { create(:user, :admin) }

    let(:project3) { create(:project) }
    let(:project4) { create(:project) }

    context 'with successful requests' do
      context 'when disassociating a project' do
        let(:project_ids) { [project3.id, project4.id] }

        it 'reassigns associated projects and returns success response' do
          expect(execute).to be_success

          runner.reload

          expect(runner.owner_project).to eq(owner_project)
          expect(runner.projects.ids).to match_array([owner_project.id] + project_ids)
        end
      end

      context 'when disassociating no projects' do
        let(:project_ids) { [project2.id, project3.id] }

        it 'reassigns associated projects and returns success response' do
          expect(execute).to be_success

          runner.reload

          expect(runner.owner_project).to eq(owner_project)
          expect(runner.projects.ids).to match_array([owner_project.id] + project_ids)
        end
      end

      context 'when disassociating all projects' do
        let(:project_ids) { [] }

        it 'reassigns associated projects and returns success response' do
          expect(execute).to be_success

          runner.reload

          expect(runner.owner_project).to eq(owner_project)
          expect(runner.projects.ids).to contain_exactly(owner_project.id)
        end
      end
    end

    context 'with failing assign_to requests' do
      let(:project_ids) { [project3.id, project4.id] }

      it 'returns error response and rolls back transaction' do
        expect(runner).to receive(:assign_to).with(project4, user).once.and_return(false)

        expect(execute).to be_error
        expect(runner.reload.projects).to eq(original_projects)
      end
    end

    context 'with failing destroy calls' do
      let(:project_ids) { [project3.id, project4.id] }

      it 'returns error response and rolls back transaction' do
        allow_next_found_instance_of(Ci::RunnerProject) do |runner_project|
          allow(runner_project).to receive(:destroy).and_return(false)
        end

        expect(execute).to be_error
        expect(runner.reload.projects).to eq(original_projects)
      end
    end
  end
end
