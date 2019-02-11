# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20190206144959_change_issuable_states_to_integer.rb')

describe AddStateIdToIssuables, :migration do
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
        nil_state_issue = issues.create!(description: 'third', state: nil)

        migrate!

        issues.reset_column_information
        expect(opened_issue.reload.state).to eq(Issue.states.opened)
        expect(closed_issue.reload.state).to eq(Issue.states.closed)
        expect(nil_state_issue.reload.state).to eq(nil)
      end
    end

    context 'merge requests' do
      it 'migrates state column to integer' do
        opened_merge_request = merge_requests.create!(state: 'opened', target_project_id: @project.id, target_branch: 'feature1', source_branch: 'master')
        closed_merge_request = merge_requests.create!(state: 'closed', target_project_id: @project.id, target_branch: 'feature2', source_branch: 'master')
        merged_merge_request = merge_requests.create!(state: 'merged', target_project_id: @project.id, target_branch: 'feature3', source_branch: 'master')
        locked_merge_request = merge_requests.create!(state: 'locked', target_project_id: @project.id, target_branch: 'feature4', source_branch: 'master')
        nil_state_merge_request = merge_requests.create!(state: nil, target_project_id: @project.id, target_branch: 'feature5', source_branch: 'master')

        migrate!

        merge_requests.reset_column_information
        expect(opened_merge_request.reload.state).to eq(MergeRequest.states.opened)
        expect(closed_merge_request.reload.state).to eq(MergeRequest.states.closed)
        expect(merged_merge_request.reload.state).to eq(MergeRequest.states.merged)
        expect(locked_merge_request.reload.state).to eq(MergeRequest.states.locked)
        expect(nil_state_merge_request.reload.state).to eq(nil)
      end
    end
  end

  describe '#down' do
    context 'issues' do
      it 'migrates state column to string' do
        opened_issue = issues.create!(description: 'first', state: 1)
        closed_issue = issues.create!(description: 'second', state: 2)
        nil_state_issue = issues.create!(description: 'third', state: nil)

        migration.down

        issues.reset_column_information
        expect(opened_issue.reload.state).to eq('opened')
        expect(closed_issue.reload.state).to eq('closed')
        expect(nil_state_issue.reload.state).to eq(nil)
      end
    end

    context 'merge requests' do
      it 'migrates state column to string' do
        opened_merge_request = merge_requests.create!(state: 1, target_project_id: @project.id, target_branch: 'feature1', source_branch: 'master')
        closed_merge_request = merge_requests.create!(state: 2, target_project_id: @project.id, target_branch: 'feature2', source_branch: 'master')
        merged_merge_request = merge_requests.create!(state: 3, target_project_id: @project.id, target_branch: 'feature3', source_branch: 'master')
        locked_merge_request = merge_requests.create!(state: 4, target_project_id: @project.id, target_branch: 'feature4', source_branch: 'master')
        nil_state_merge_request = merge_requests.create!(state: nil, target_project_id: @project.id, target_branch: 'feature5', source_branch: 'master')

        migration.down

        merge_requests.reset_column_information
        expect(opened_merge_request.reload.state).to eq('opened')
        expect(closed_merge_request.reload.state).to eq('closed')
        expect(merged_merge_request.reload.state).to eq('merged')
        expect(locked_merge_request.reload.state).to eq('locked')
        expect(nil_state_merge_request.reload.state).to eq(nil)
      end
    end
  end
end
