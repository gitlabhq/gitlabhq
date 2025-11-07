# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::UnlinkProjectForksWorker, feature_category: :source_code_management do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:source_project) { create(:project, :repository) }

  let_it_be(:project1) do
    source_project.add_developer(user)
    fork_project(source_project, user, { repository: true, namespace: group })
  end

  let_it_be(:project2) { fork_project(source_project, user, { repository: true, namespace: group }) }
  let_it_be(:non_forked_project) { create(:project, namespace: group) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'unlinks fork relationships for projects in the group' do
      expect(project1.forked?).to be_truthy
      expect(project2.forked?).to be_truthy

      worker.perform(group.id, user.id)

      expect(project1.reload.forked?).to be_falsey
      expect(project2.reload.forked?).to be_falsey
    end

    it 'does not affect non-forked projects' do
      expect(non_forked_project.forked?).to be_falsey

      worker.perform(group.id, user.id)

      expect(non_forked_project.reload.forked?).to be_falsey
    end

    it 'calls UnlinkForkService for each forked project in the group' do
      expect(Projects::UnlinkForkService).to receive(:new).with(project1, user).and_call_original
      expect(Projects::UnlinkForkService).to receive(:new).with(project2, user).and_call_original
      expect(Projects::UnlinkForkService).not_to receive(:new).with(non_forked_project, user)

      worker.perform(group.id, user.id)
    end

    context 'when group does not exist' do
      it 'does not raise an error' do
        expect { worker.perform(non_existing_record_id, user.id) }.not_to raise_error
      end

      it 'does not call UnlinkForkService' do
        expect(Projects::UnlinkForkService).not_to receive(:new)

        worker.perform(non_existing_record_id, user.id)
      end
    end

    context 'when user does not exist' do
      it 'does not raise an error' do
        expect { worker.perform(group.id, non_existing_record_id) }.not_to raise_error
      end

      it 'does not call UnlinkForkService' do
        expect(Projects::UnlinkForkService).not_to receive(:new)

        worker.perform(group.id, non_existing_record_id)
      end
    end

    context 'when group has no projects' do
      let(:empty_group) { create(:group) }

      it 'does not call UnlinkForkService' do
        expect(Projects::UnlinkForkService).not_to receive(:new)

        worker.perform(empty_group.id, user.id)
      end
    end

    context 'with subgroups' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subgroup_project) { fork_project(source_project, user, { repository: true, namespace: subgroup }) }

      it 'calls UnlinkForkService for projects in subgroups too' do
        expect(Projects::UnlinkForkService).to receive(:new).with(project1, user).and_call_original
        expect(Projects::UnlinkForkService).to receive(:new).with(project2, user).and_call_original
        expect(Projects::UnlinkForkService).to receive(:new).with(subgroup_project, user).and_call_original

        worker.perform(group.id, user.id)
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group.id, user.id] }

    it 'can be run multiple times without side effects' do
      # First run - processes both projects
      expect(Projects::UnlinkForkService).to receive(:new).twice.and_call_original
      worker.perform(*job_args)

      # Second run - projects already unlinked, no work to do (idempotent)
      expect(Projects::UnlinkForkService).not_to receive(:new)
      worker.perform(*job_args)
    end
  end
end
