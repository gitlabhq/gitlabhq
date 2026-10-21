# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CopyAiSuggestedReviewersToPartitionedTable, feature_category: :code_review_workflow do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: 'group', path: 'group', organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:user_a) { create_user('a') }
  let(:user_b) { create_user('b') }

  let(:source_table) { table(:ai_suggested_reviewers) }
  let(:target_table) { table(:p_ai_suggested_reviewers, primary_key: :id) }

  describe '#up' do
    it 'copies the recent suggestions in id order and skips old ones and merge requests that have new suggestions' do
      stub_const("#{described_class}::BATCH_SIZE", 1)

      recent_merge_request = create_merge_request('recent')
      old_merge_request = create_merge_request('old')
      regenerated_merge_request = create_merge_request('regenerated')

      create_source_row(recent_merge_request, user_b, 2.days.ago, 'second')
      create_source_row(recent_merge_request, user_a, 1.day.ago, 'third')
      create_source_row(old_merge_request, user_a, 31.days.ago, 'old')
      create_source_row(regenerated_merge_request, user_a, 1.day.ago, 'stale')
      target_table.create!(
        project_id: project.id, merge_request_id: regenerated_merge_request.id, user_id: user_b.id,
        reason: 'regenerated', created_at: Time.current, updated_at: Time.current
      )

      migrate!

      expect(target_table.order(:id).pluck(:merge_request_id, :user_id, :reason)).to eq([
        [regenerated_merge_request.id, user_b.id, 'regenerated'],
        [recent_merge_request.id, user_b.id, 'second'],
        [recent_merge_request.id, user_a.id, 'third']
      ])
    end
  end

  def create_user(name)
    table(:users).create!(
      email: "#{name}@example.com", username: name, projects_limit: 0, organization_id: organization.id
    )
  end

  def create_merge_request(branch)
    table(:merge_requests).create!(
      target_project_id: project.id, source_project_id: project.id,
      source_branch: branch, target_branch: 'master', title: branch
    )
  end

  def create_source_row(merge_request, user, created_at, reason)
    source_table.create!(
      project_id: project.id, merge_request_id: merge_request.id, user_id: user.id,
      reason: reason, created_at: created_at, updated_at: created_at
    )
  end
end
