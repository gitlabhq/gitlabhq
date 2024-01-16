# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillInternalIdsWithIssuesUsageForEpics, feature_category: :team_planning do
  let(:internal_ids) { table(:internal_ids) }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }

  let!(:author) { users.create!(projects_limit: 0, email: 'human@example.com') }

  let!(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let!(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group') }
  let!(:group3) { namespaces.create!(name: 'group3', path: 'group3', type: 'Group') }
  let!(:group4) { namespaces.create!(name: 'group4', path: 'group4', type: 'Group') }
  let!(:project_namespace) { namespaces.create!(name: 'project1', path: 'project1', type: 'Project') }

  let!(:project_issue_iid) { internal_ids.create!(namespace_id: project_namespace.id, usage: 0, last_value: 100) }
  let!(:group1_epic_iid) { internal_ids.create!(namespace_id: group1.id, usage: 4, last_value: 100) }

  # when there are issues and epics usage records for same namespace and EPICS usage last_value is higher
  let!(:group2_issue_iid) { internal_ids.create!(namespace_id: group2.id, usage: 0, last_value: 100) }
  let!(:group2_epic_iid) { internal_ids.create!(namespace_id: group2.id, usage: 4, last_value: 110) }

  # when there are issues and epics usage records for same namespace and ISSUES usage last_value is higher
  let!(:group3_issue_iid) { internal_ids.create!(namespace_id: group3.id, usage: 0, last_value: 100) }
  let!(:group3_epic_iid) { internal_ids.create!(namespace_id: group3.id, usage: 4, last_value: 110) }

  let!(:group4_epic) do
    epics.create!(title: 'Epic99', title_html: 'Epic99', group_id: group4.id, iid: 99, author_id: author.id)
  end

  describe '#up' do
    it 'backfills internal_ids for epics as group level issues' do
      issues_iid_namespaces = [group1.id, group2.id, group3.id, group4.id, project_namespace.id]
      # project, group2, group3
      expect(internal_ids.where(usage: 0).count).to eq(3)
      # group1, group2, group3
      expect(internal_ids.where(usage: 4).count).to eq(3)
      migrate!

      # project1, group1, group2, group3, group4(this just had the epics record but not the internal_ids record)
      expect(internal_ids.where(usage: 0).count).to eq(5)
      expect(internal_ids.where(usage: 0).pluck(:namespace_id)).to match_array(issues_iid_namespaces)
      expect(internal_ids.where(usage: 0, namespace_id: group2.id).first.last_value).to eq(110)
      expect(internal_ids.where(usage: 0, namespace_id: group3.id).first.last_value).to eq(110)
      expect(internal_ids.where(usage: 4).count).to eq(0)
    end
  end
end
