# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::MergeRequestCreator, feature_category: :importers do
  let(:project) { create(:project, :repository) }
  let_it_be(:reviewer_user) { create(:user) }

  subject { described_class.new(project) }

  describe '#execute' do
    let(:attributes) do
      HashWithIndifferentAccess.new(
        merge_request.attributes.except('merge_params', 'suggested_reviewers')
        .merge(reviewer_ids: [reviewer_user.id], imported_from: 0)
      )
    end

    context 'merge request already exists' do
      let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
      let(:commits) { merge_request.merge_request_diffs.first.commits }

      it 'updates the data' do
        commits_count = commits.count
        merge_request.merge_request_diffs.destroy_all # rubocop: disable Cop/DestroyAll

        expect(merge_request.merge_request_diffs.count).to eq(0)

        subject.execute(attributes)

        merge_request.reload

        expect(merge_request.reviewer_ids).to contain_exactly(reviewer_user.id)
        expect(merge_request.merge_request_diffs.count).to eq(1)
        expect(merge_request.merge_request_diffs.first.commits.count).to eq(commits_count)
        expect(merge_request.latest_merge_request_diff_id).to eq(merge_request.merge_request_diffs.first.id)
      end
    end

    context 'new merge request' do
      let(:merge_request) { build(:merge_request, target_project: project, source_project: project) }

      it 'creates a new merge request' do
        attributes.delete(:id)

        expect { subject.execute(attributes) }.to change { MergeRequest.count }.by(1)

        new_mr = MergeRequest.last
        expect(new_mr.merge_request_diffs.count).to eq(1)
      end
    end
  end
end
