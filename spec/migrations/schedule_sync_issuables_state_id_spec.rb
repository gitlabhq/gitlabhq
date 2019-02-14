# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190214112022_schedule_sync_issuables_state_id.rb')

describe ScheduleSyncIssuablesStateId, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:issues) { table(:issues) }
  let(:migration) { described_class.new }

  before do
    @group = namespaces.create!(name: 'gitlab', path: 'gitlab')
    @project = projects.create!(namespace_id: @group.id)
  end

  describe '#up' do
    context 'issues' do
      it 'migrates state column to integer' do
        opened_issue = issues.create!(description: 'first', state: 'opened')
        closed_issue = issues.create!(description: 'second', state: 'closed')
        invalid_state_issue = issues.create!(description: 'fourth', state: 'not valid')
        nil_state_issue = issues.create!(description: 'third', state: nil)

        migrate!

        expect(opened_issue.reload.state_id).to eq(Issue.available_states[:opened])
        expect(closed_issue.reload.state_id).to eq(Issue.available_states[:closed])
        expect(invalid_state_issue.reload.state_id).to be_nil
        expect(nil_state_issue.reload.state_id).to be_nil
      end
    end

    context 'merge requests' do
      it 'migrates state column to integer' do
        opened_merge_request = merge_requests.create!(state: 'opened', target_project_id: @project.id, target_branch: 'feature1', source_branch: 'master')
        closed_merge_request = merge_requests.create!(state: 'closed', target_project_id: @project.id, target_branch: 'feature2', source_branch: 'master')
        merged_merge_request = merge_requests.create!(state: 'merged', target_project_id: @project.id, target_branch: 'feature3', source_branch: 'master')
        locked_merge_request = merge_requests.create!(state: 'locked', target_project_id: @project.id, target_branch: 'feature4', source_branch: 'master')
        invalid_state_merge_request = merge_requests.create!(state: 'not valid', target_project_id: @project.id, target_branch: 'feature5', source_branch: 'master')

        migrate!

        expect(opened_merge_request.reload.state_id).to eq(MergeRequest.available_states[:opened])
        expect(closed_merge_request.reload.state_id).to eq(MergeRequest.available_states[:closed])
        expect(merged_merge_request.reload.state_id).to eq(MergeRequest.available_states[:merged])
        expect(locked_merge_request.reload.state_id).to eq(MergeRequest.available_states[:locked])
        expect(invalid_state_merge_request.reload.state_id).to be_nil
      end
    end
  end
end
