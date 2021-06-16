# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SyncIssuablesStateId do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:issues) { table(:issues) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:merge_requests) { table(:merge_requests) }
    let(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab') }
    let(:project) { projects.create!(namespace_id: group.id) }
    # These state_ids should be the same defined on Issue/MergeRequest models
    let(:state_ids) { { opened: 1, closed: 2, merged: 3, locked: 4 } }

    it 'migrates state column to state_id as integer' do
      opened_issue = issues.create!(description: 'first', state: 'opened')
      closed_issue = issues.create!(description: 'second', state: 'closed')
      unknown_state_issue = issues.create!(description: 'second', state: 'unknown')
      opened_merge_request = merge_requests.create!(state: 'opened', target_project_id: project.id, target_branch: 'feature1', source_branch: 'master')
      closed_merge_request = merge_requests.create!(state: 'closed', target_project_id: project.id, target_branch: 'feature2', source_branch: 'master')
      merged_merge_request = merge_requests.create!(state: 'merged', target_project_id: project.id, target_branch: 'feature3', source_branch: 'master')
      locked_merge_request = merge_requests.create!(state: 'locked', target_project_id: project.id, target_branch: 'feature4', source_branch: 'master')
      unknown_state_merge_request = merge_requests.create!(state: 'unknown', target_project_id: project.id, target_branch: 'feature4', source_branch: 'master')

      migrate!

      expect(opened_issue.reload.state_id).to eq(state_ids[:opened])
      expect(closed_issue.reload.state_id).to eq(state_ids[:closed])
      expect(unknown_state_issue.reload.state_id).to eq(state_ids[:closed])
      expect(opened_merge_request.reload.state_id).to eq(state_ids[:opened])
      expect(closed_merge_request.reload.state_id).to eq(state_ids[:closed])
      expect(merged_merge_request.reload.state_id).to eq(state_ids[:merged])
      expect(locked_merge_request.reload.state_id).to eq(state_ids[:locked])
      expect(unknown_state_merge_request.reload.state_id).to eq(state_ids[:closed])
    end
  end
end
