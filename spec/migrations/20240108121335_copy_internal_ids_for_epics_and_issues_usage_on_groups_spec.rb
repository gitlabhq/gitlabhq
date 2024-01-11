# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CopyInternalIdsForEpicsAndIssuesUsageOnGroups, feature_category: :team_planning do
  let(:internal_ids) { table(:internal_ids) }
  let(:namespaces) { table(:namespaces) }

  let!(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let!(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group') }
  let!(:group3) { namespaces.create!(name: 'group3', path: 'group3', type: 'Group') }
  let!(:project_namespace) { namespaces.create!(name: 'project1', path: 'project1', type: 'Project') }

  let!(:project_issue_iid) { internal_ids.create!(namespace_id: project_namespace.id, usage: 0, last_value: 100) }
  let!(:group1_epic_iid) { internal_ids.create!(namespace_id: group1.id, usage: 4, last_value: 101) }
  let!(:group2_issue_iid) { internal_ids.create!(namespace_id: group2.id, usage: 0, last_value: 102) }
  let!(:group2_epic_iid) { internal_ids.create!(namespace_id: group2.id, usage: 4, last_value: 103) }

  describe '#on_update' do
    it 'updates corresponding usage record between epics and issues' do
      # create the triggers
      migrate!

      # initially there is no record for issues usage for group1
      expect(internal_ids.where(usage: 0, namespace_id: group1.id).count).to eq(0)
      # when epics usage record is updated the issues usage record is created and last_value is copied
      group1_epic_iid.update!(last_value: 1000)
      expect(internal_ids.where(usage: 0, namespace_id: group1.id).first.last_value).to eq(1000)

      # when there is an issues usage record:
      expect(internal_ids.where(usage: 0, namespace_id: group2.id).first.last_value).to eq(102)
      # updates the issues usage record when epics usage record is updated
      group2_epic_iid.update!(last_value: 1000)
      expect(internal_ids.where(usage: 0, namespace_id: group2.id).first.last_value).to eq(1000)

      expect(internal_ids.where(usage: 4, namespace_id: group2.id).first.last_value).to eq(1000)
      group2_issue_iid.update!(last_value: 2000)
      expect(internal_ids.where(usage: 4, namespace_id: group2.id).first.last_value).to eq(2000)
    end
  end

  describe '#on_insert' do
    it 'inserts corresponding usage record between epics and issues' do
      migrate!

      expect(internal_ids.where(usage: 0, namespace_id: group3.id).count).to eq(0)
      expect(internal_ids.where(usage: 4, namespace_id: group3.id).count).to eq(0)

      # create record for epics usage
      internal_ids.create!(namespace_id: group3.id, usage: 4, last_value: 1000)

      expect(internal_ids.where(usage: 0, namespace_id: group3.id).first.last_value).to eq(1000)
      expect(internal_ids.where(usage: 4, namespace_id: group3.id).first.last_value).to eq(1000)

      # cleanup records for group3
      internal_ids.where(namespace_id: group3.id).delete_all

      expect(internal_ids.where(usage: 0, namespace_id: group3.id).count).to eq(0)
      expect(internal_ids.where(usage: 4, namespace_id: group3.id).count).to eq(0)

      # create record for issues usage
      internal_ids.create!(namespace_id: group3.id, usage: 0, last_value: 1000)

      expect(internal_ids.where(usage: 0, namespace_id: group3.id).first.last_value).to eq(1000)
      expect(internal_ids.where(usage: 4, namespace_id: group3.id).first.last_value).to eq(1000)
    end
  end
end
