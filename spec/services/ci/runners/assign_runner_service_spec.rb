# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::AssignRunnerService, '#execute', feature_category: :runner do
  let_it_be(:organization1) { create(:organization) }
  let_it_be(:owner_group) { create(:group, organization: organization1) }
  let_it_be(:owner_project) { create(:project, group: owner_group, organization: organization1) }
  let_it_be(:new_project) { create(:project, organization: organization1) }

  let(:service) { described_class.new(runner, new_project, user) }
  let(:runner) { create(:ci_runner, :project, projects: [owner_project]) }

  subject(:execute) { service.execute }

  context 'without user' do
    let(:user) { nil }

    it 'does not call assign_to on runner and returns error response', :aggregate_failures do
      expect(runner).not_to receive(:assign_to)

      expect(execute).to be_error
      expect(execute.reason).to eq(:not_authorized_to_assign_runner)
      expect(execute.message).to eq(_('user not allowed to assign runner'))
    end
  end

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call assign_to on runner and returns error message' do
      expect(runner).not_to receive(:assign_to)

      expect(execute).to be_error
      expect(execute.reason).to eq(:not_authorized_to_assign_runner)
      expect(execute.message).to eq(_('user not allowed to assign runner'))
    end
  end

  context 'with authorized user' do
    let(:user) { create(:user) }

    context 'with user owning runner and being maintainer of new project' do
      before do
        owner_project.group.add_owner(user)
        new_project.add_maintainer(user)
      end

      it 'calls assign_to on runner and returns success response' do
        expect(runner).to receive(:assign_to).with(new_project, user).once.and_call_original

        expect(execute).to be_success
      end

      context 'when runner returns error' do
        let(:new_project) { owner_project }

        it 'returns error response' do
          expect(execute).to be_error
          expect(execute.reason).to eq(:runner_error)
          expect(execute.errors).to contain_exactly(
            'Assign to Validation failed: Runner projects runner has already been taken')
        end
      end

      context 'when new project is from a different organization' do
        let_it_be(:organization2) { create(:organization) }
        let_it_be(:new_project) { create(:project, organization: organization2) }

        it 'returns error response and rolls back transaction' do
          expect(execute).to be_error
          expect(execute.reason).to eq(:project_not_in_same_organization)
          expect(execute.errors).to contain_exactly(
            _('runner can only be assigned to projects in the same organization')
          )
          expect(runner.reload.projects).to contain_exactly(owner_project)
        end
      end
    end

    context 'with user owning runner' do
      before do
        owner_project.add_maintainer(user)
      end

      it 'does not call assign_to on runner and returns error message', :aggregate_failures do
        expect(runner).not_to receive(:assign_to)

        expect(execute).to be_error
        expect(execute.reason).to eq(:not_authorized_to_add_runner_in_project)
        expect(execute.message).to eq(_('user is not authorized to add runners to project'))
      end
    end

    context 'with user being maintainer of new project', :aggregate_failures do
      before do
        new_project.add_maintainer(user)
      end

      it 'does not call assign_to on runner and returns error message' do
        expect(runner).not_to receive(:assign_to)

        expect(execute).to be_error
        expect(execute.reason).to eq(:not_authorized_to_assign_runner)
        expect(execute.message).to eq('user not allowed to assign runner')
      end
    end
  end

  context 'with admin user', :enable_admin_mode do
    let_it_be(:user) { create(:user, :admin) }

    it 'calls assign_to on runner and returns success response' do
      expect(runner).to receive(:assign_to).with(new_project, user).once.and_call_original

      expect(execute).to be_success
    end

    context 'when runner is not associated with any projects' do
      let(:runner) { create(:ci_runner, :project, :without_projects) }

      it 'calls assign_to on runner and returns success response' do
        expect(runner).to receive(:assign_to).with(new_project, user).once.and_call_original

        expect(execute).to be_success
      end
    end
  end
end
