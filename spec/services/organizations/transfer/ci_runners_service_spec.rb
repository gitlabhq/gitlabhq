# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Transfer::CiRunnersService, :aggregate_failures, feature_category: :runner_core do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be(:group, freeze: true) { create(:group, organization: old_organization) }
  let_it_be(:subgroup, freeze: true) { create(:group, parent: group, organization: old_organization) }
  let_it_be(:project, freeze: true) { create(:project, namespace: subgroup, organization: old_organization) }

  let_it_be(:tag) { create(:ci_tag) }

  let_it_be_with_refind(:group_runner) do
    create(:ci_runner, :group, groups: [group], organization_id: old_organization.id)
  end

  let_it_be_with_refind(:subgroup_runner) do
    create(:ci_runner, :group, groups: [subgroup], organization_id: old_organization.id)
  end

  let_it_be_with_refind(:project_runner) do
    create(:ci_runner, :project, projects: [project], organization_id: old_organization.id)
  end

  let_it_be_with_refind(:group_runner_manager) do
    create(:ci_runner_machine, runner: group_runner)
  end

  let_it_be_with_refind(:subgroup_runner_manager) do
    create(:ci_runner_machine, runner: subgroup_runner)
  end

  let_it_be_with_refind(:project_runner_manager) do
    create(:ci_runner_machine, runner: project_runner)
  end

  let_it_be_with_refind(:group_runner_tagging) do
    create(:ci_runner_tagging, runner: group_runner, tag: tag)
  end

  let_it_be_with_refind(:subgroup_runner_tagging) do
    create(:ci_runner_tagging, runner: subgroup_runner, tag: tag)
  end

  let_it_be_with_refind(:project_runner_tagging) do
    create(:ci_runner_tagging, runner: project_runner, tag: tag)
  end

  subject(:execute) do
    described_class.new(
      group: group,
      old_organization: old_organization,
      new_organization: new_organization
    ).execute
  end

  describe '#execute' do
    it 'updates organization_id for group runners' do
      execute

      expect(group_runner.reload.organization_id).to eq(new_organization.id)
      expect(subgroup_runner.reload.organization_id).to eq(new_organization.id)
    end

    it 'updates organization_id for project runners' do
      execute

      expect(project_runner.reload.organization_id).to eq(new_organization.id)
    end

    it 'updates organization_id for runner managers' do
      execute

      expect(group_runner_manager.reload.organization_id).to eq(new_organization.id)
      expect(subgroup_runner_manager.reload.organization_id).to eq(new_organization.id)
      expect(project_runner_manager.reload.organization_id).to eq(new_organization.id)
    end

    it 'updates organization_id for runner taggings' do
      execute

      expect(group_runner_tagging.reload.organization_id).to eq(new_organization.id)
      expect(subgroup_runner_tagging.reload.organization_id).to eq(new_organization.id)
      expect(project_runner_tagging.reload.organization_id).to eq(new_organization.id)
    end

    context 'when runners belong to a different group' do
      let_it_be(:other_group, freeze: true) { create(:group, organization: old_organization) }
      let_it_be_with_refind(:other_group_runner) do
        create(:ci_runner, :group, groups: [other_group], organization_id: old_organization.id)
      end

      let_it_be_with_refind(:other_runner_manager) do
        create(:ci_runner_machine, runner: other_group_runner)
      end

      let_it_be_with_refind(:other_runner_tagging) do
        create(:ci_runner_tagging, runner: other_group_runner, tag: tag)
      end

      it 'does not update runners belonging to other groups' do
        execute

        expect(other_group_runner.reload.organization_id).to eq(old_organization.id)
        expect(other_runner_manager.reload.organization_id).to eq(old_organization.id)
        expect(other_runner_tagging.reload.organization_id).to eq(old_organization.id)
      end
    end

    context 'when batching updates' do
      it 'processes records in batches' do
        stub_const(
          "Organizations::Transfer::Concerns::OrganizationUpdater::ORGANIZATION_ID_UPDATE_BATCH_SIZE", 1
        )

        runner_batch_count = 0
        allow(Ci::Runner).to receive(:each_batch).and_wrap_original do |method, **kwargs, &block|
          method.call(**kwargs) do |batch|
            runner_batch_count += 1
            block.call(batch)
          end
        end

        execute

        expect(runner_batch_count).to be >= 2
        expect(group_runner.reload.organization_id).to eq(new_organization.id)
        expect(subgroup_runner.reload.organization_id).to eq(new_organization.id)
        expect(project_runner.reload.organization_id).to eq(new_organization.id)
      end
    end
  end
end
