# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphanedPipelineExecutionProjectSchedules, feature_category: :security_policy_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }
  let(:security_policies) { table(:security_policies) }
  let(:security_policy_project_links) { table(:security_policy_project_links) }
  let(:schedules) { table(:security_pipeline_execution_project_schedules) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let!(:group_namespace) do
    namespaces.create!(organization_id: organization.id, name: 'group', path: 'group', type: 'Group')
  end

  let!(:policy_project) { create_project('policy-project', group_namespace) }
  let!(:target_project) { create_project('target-project', group_namespace) }

  let!(:policy_configuration) do
    security_orchestration_policy_configurations.create!(
      namespace_id: group_namespace.id,
      security_policy_management_project_id: policy_project.id
    )
  end

  let!(:security_policy) { create_policy(0) }

  def create_policy(index)
    security_policies.create!(
      type: 4, # pipeline_execution_schedule_policy
      policy_index: index,
      name: "Scheduled policy #{index}",
      enabled: true,
      checksum: index.to_s * 64,
      scope: {},
      content: {},
      security_policy_management_project_id: policy_project.id,
      security_orchestration_policy_configuration_id: policy_configuration.id
    )
  end

  def create_schedule(project)
    schedules.create!(
      project_id: project.id,
      security_policy_id: security_policy.id,
      next_run_at: 1.day.from_now,
      time_window_seconds: 4.hours.to_i,
      cron: '0 0 * * *',
      cron_timezone: 'UTC'
    )
  end

  def create_project(name, group)
    project_namespace = namespaces.create!(
      name: name, path: name, type: 'Project', organization_id: group.organization_id
    )

    projects.create!(
      organization_id: group.organization_id,
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      name: name,
      path: name
    )
  end

  context 'when the schedule has no matching security_policy_project_links row' do
    let!(:orphaned_schedule) { create_schedule(target_project) }

    it 'deletes the orphaned schedule' do
      expect { migrate! }.to change { schedules.count }.by(-1)

      expect(schedules.find_by(id: orphaned_schedule.id)).to be_nil
    end
  end

  context 'when the schedule has a matching security_policy_project_links row' do
    let!(:linked_schedule) { create_schedule(target_project) }

    before do
      security_policy_project_links.create!(project_id: target_project.id, security_policy_id: security_policy.id)
    end

    it 'does not delete the schedule' do
      expect { migrate! }.not_to change { schedules.count }

      expect(schedules.find_by(id: linked_schedule.id)).to be_present
    end
  end

  context 'when the project is only linked to a different policy' do
    let!(:orphaned_schedule) { create_schedule(target_project) }
    let!(:other_policy) { create_policy(1) }

    before do
      security_policy_project_links.create!(project_id: target_project.id, security_policy_id: other_policy.id)
    end

    it 'deletes the schedule' do
      expect { migrate! }.to change { schedules.count }.by(-1)

      expect(schedules.find_by(id: orphaned_schedule.id)).to be_nil
    end
  end

  context 'when there is a mix of orphaned and linked schedules across batches' do
    let!(:orphaned_schedule) { create_schedule(target_project) }
    let!(:other_project) { create_project('other-project', group_namespace) }
    let!(:linked_schedule) { create_schedule(other_project) }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      security_policy_project_links.create!(project_id: other_project.id, security_policy_id: security_policy.id)
    end

    it 'only deletes the orphaned schedule' do
      expect { migrate! }.to change { schedules.count }.by(-1)

      expect(schedules.find_by(id: orphaned_schedule.id)).to be_nil
      expect(schedules.find_by(id: linked_schedule.id)).to be_present
    end
  end
end
