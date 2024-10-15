# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::MergeRequestBasic, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:labels) { create_list(:label, 3) }
  let_it_be(:merge_requests) { create_list(:labeled_merge_request, 10, :unique_branches, labels: labels) }
  let_it_be(:entity) { described_class.new(merge_request) }

  # This mimics the behavior of the `Grape::Entity` serializer
  def present(obj)
    described_class.new(obj).presented
  end

  subject(:json) { entity.as_json }

  it 'includes expected fields' do
    expected_fields = %i[
      merged_by merge_user merged_at closed_by closed_at target_branch user_notes_count upvotes downvotes
      author assignees assignee reviewers source_project_id target_project_id labels draft work_in_progress
      milestone merge_when_pipeline_succeeds merge_status detailed_merge_status merge_after sha merge_commit_sha
      squash_commit_sha discussion_locked should_remove_source_branch force_remove_source_branch prepared_at
      reference references web_url time_stats squash task_completion_status has_conflicts blocking_discussions_resolved
      imported imported_from
    ]

    is_expected.to include(*expected_fields)
  end

  context "with :with_api_entity_associations scope" do
    let(:scope) { MergeRequest.with_api_entity_associations }

    it "avoids N+1 queries" do
      query = scope.find(merge_request.id)

      control = ActiveRecord::QueryRecorder.new do
        present(query).to_json
      end

      # stub the `head_commit_sha` as it will trigger a
      # backward compatibility query that is out-of-scope
      # for this test whenever it is `nil`
      allow_any_instance_of(MergeRequestDiff).to receive(:head_commit_sha).and_return(Gitlab::Git::SHA1_BLANK_SHA)

      query = scope.all
      batch = ActiveRecord::QueryRecorder.new do
        entities = query.map(&method(:present))

        entities.to_json
      end

      # The current threshold is 3 query per entity maximum.
      expect(batch.count).to be_within(3 * query.count).of(control.count)
    end
  end

  describe 'reviewers' do
    before do
      merge_request.reviewers = [user]
    end

    it 'includes assigned reviewers' do
      result = Gitlab::Json.parse(present(merge_request).to_json)

      expect(result['reviewers'][0]['username']).to eq user.username
    end
  end

  describe 'squash' do
    subject { json[:squash] }

    before do
      merge_request.target_project.project_setting.update!(squash_option: :never)
      merge_request.update!(squash: true)
    end

    it { is_expected.to eq(true) }
  end

  describe 'squash_on_merge' do
    subject { json[:squash_on_merge] }

    before do
      merge_request.target_project.project_setting.update!(squash_option: :never)
      merge_request.update!(squash: true)
    end

    it { is_expected.to eq(false) }
  end
end
