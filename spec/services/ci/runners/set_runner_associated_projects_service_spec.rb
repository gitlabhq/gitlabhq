# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::SetRunnerAssociatedProjectsService, '#execute', feature_category: :runner do
  subject(:execute) do
    described_class.new(runner: runner, current_user: user, project_ids: new_projects.map(&:id)).execute
  end

  let_it_be(:organization1) { create(:organization) }
  let_it_be(:owner_project) { create(:project, organization: organization1) }
  let_it_be(:project2) { create(:project, organization: organization1) }

  let(:original_projects) { [owner_project, project2] }
  let(:runner) { create(:ci_runner, :project, projects: original_projects) }

  context 'without user' do
    let(:user) { nil }
    let(:new_projects) { [project2] }

    it 'does not call assign_to on runner and returns error response', :aggregate_failures do
      expect(runner).not_to receive(:assign_to)

      expect(execute).to be_error
      expect(execute.reason).to eq(:not_authorized_to_assign_runner)
      expect(execute.message).to eq(_('user not allowed to assign runner'))
    end
  end

  context 'with unauthorized user' do
    let(:user) { create(:user) }
    let(:new_projects) { [project2] }

    it 'does not call assign_to on runner and returns error message' do
      expect(runner).not_to receive(:assign_to)

      expect(execute).to be_error
      expect(execute.reason).to eq(:not_authorized_to_assign_runner)
      expect(execute.message).to eq(_('user not allowed to assign runner'))
    end
  end

  context 'with authorized user' do
    let_it_be(:project3) { create(:project, organization: organization1) }
    let_it_be(:project4) { create(:project, organization: organization1) }

    let(:projects_with_maintainer_access) { original_projects }

    before do
      projects_with_maintainer_access.each { |project| project.add_maintainer(user) }
    end

    shared_context 'with successful requests' do
      context 'when disassociating a project' do
        let(:new_projects) { [project3, project4] }

        it 'reassigns associated projects and returns success response' do
          expect(execute).to be_success

          runner.reload

          expect(runner.owner_project).to eq(owner_project)
          expect(runner.projects.ids).to match_array([owner_project, *new_projects].map(&:id))
        end
      end

      context 'when disassociating no projects' do
        let(:new_projects) { [project2, project3] }

        it 'reassigns associated projects and returns success response' do
          expect(execute).to be_success

          runner.reload

          expect(runner.owner_project).to eq(owner_project)
          expect(runner.projects.ids).to eq([owner_project, *new_projects].map(&:id))
        end
      end

      context 'when disassociating all projects' do
        let(:new_projects) { [] }

        it 'reassigns associated projects and returns success response' do
          expect(execute).to be_success

          runner.reload

          expect(runner.owner_project).to eq(owner_project)
          expect(runner.projects.ids).to contain_exactly(owner_project.id)
        end
      end
    end

    shared_context 'with failing destroy calls' do
      let(:new_projects) { [project3, project4] }

      it 'returns error response and rolls back transaction' do
        allow_next_found_instance_of(Ci::RunnerProject) do |runner_project|
          allow(runner_project).to receive(:destroy).and_return(false)
        end

        expect(execute).to be_error
        expect(execute.reason).to eq(:failed_runner_project_destroy)
        expect(runner.reload.projects.order(:id)).to eq(original_projects)
      end
    end

    context 'with maintainer user' do
      let(:user) { create(:user) }
      let(:projects_with_maintainer_access) { original_projects + new_projects }

      it_behaves_like 'with successful requests'
      it_behaves_like 'with failing destroy calls'

      context 'when associating new projects' do
        let(:new_projects) { [project3, project4] }

        context 'with missing permissions on one of the new projects' do
          let(:projects_with_maintainer_access) { original_projects + [project3] }

          it 'returns error response and rolls back transaction' do
            expect(execute).to be_error
            expect(execute.reason).to eq(:not_authorized_to_add_runner_in_project)
            expect(execute.errors).to contain_exactly(_('user is not authorized to add runners to project'))
            expect(runner.reload.projects.order(:id)).to eq(original_projects)
          end
        end

        context 'when some of the new projects are from a different organization' do
          let_it_be(:organization2) { create(:organization) }
          let_it_be(:project4) { create(:project, organization: organization2) }

          it 'returns error response and rolls back transaction' do
            expect(execute).to be_error
            expect(execute.reason).to eq(:project_not_in_same_organization)
            expect(execute.errors).to contain_exactly(
              _('runner can only be assigned to projects in the same organization')
            )
            expect(runner.reload.projects.order(:id)).to eq(original_projects)
          end

          context 'with multiple failures' do
            let(:projects_with_maintainer_access) { original_projects + [project4] }

            it 'returns error response and rolls back transaction' do
              expect(execute).to be_error
              expect(execute.reason).to eq(:multiple_errors)
              expect(execute.errors).to contain_exactly(
                _('runner can only be assigned to projects in the same organization'),
                _('user is not authorized to add runners to project')
              )
              expect(runner.reload.projects.order(:id)).to eq(original_projects)
            end
          end
        end
      end
    end

    context 'with admin user', :enable_admin_mode do
      let(:user) { create(:user, :admin) }
      let(:projects_with_maintainer_access) { original_projects + new_projects }

      it_behaves_like 'with successful requests'
      it_behaves_like 'with failing destroy calls'
    end
  end
end
