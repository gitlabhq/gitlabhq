# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiffCompareVersionsEntity, feature_category: :code_review_workflow do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needs persisted objects
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:merge_request) do
    create(
      :merge_request,
      :skip_diff_creation,
      source_project: project,
      target_project: project
    )
  end

  let_it_be(:diff_1) { create(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:diff_2) { create(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:diff_3) { create(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:head_diff) { create(:merge_request_diff, :merge_head, merge_request: merge_request) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:options) do
    {
      diff_id: diff_1.id,
      start_sha: diff_3.head_commit_sha
    }
  end

  let(:diffable_merge_ref?) { true }
  let(:entity) { described_class.new(merge_request, options) }

  subject(:serialized) { entity.as_json }

  before_all do
    # These factories are getting created with `empty` as state so they can't be found
    # by the query used in the serializer.  We force them to be `collected` so they
    # can be found.
    [diff_1, diff_2, diff_3, head_diff].each { |diff| diff.update!(state: :collected) }
  end

  before do
    allow(merge_request).to receive(:diffable_merge_ref?).and_return(diffable_merge_ref?)
  end

  describe 'serialization' do
    it 'serializes source_versions using DiffSourceVersionEntity' do
      expect(RapidDiffs::DiffSourceVersionEntity).to receive(:represent)
        .with(
          [diff_3, diff_2, diff_1],
          merge_request: merge_request,
          merge_request_diffs: [diff_3, diff_2, diff_1],
          diff_id: options[:diff_id],
          start_sha: options[:start_sha]
        )
        .and_call_original

      expect(serialized).to have_key(:source_versions)
    end

    it 'serializes target_versions using DiffTargetVersionEntity' do
      expect(RapidDiffs::DiffTargetVersionEntity).to receive(:represent)
        .with(
          [head_diff, diff_2, diff_1],
          merge_request: merge_request,
          merge_request_diffs: [diff_3, diff_2, diff_1],
          diff_id: options[:diff_id],
          start_sha: options[:start_sha]
        )
        .and_call_original

      expect(serialized).to have_key(:target_versions)
    end

    context 'when HEAD diff is not diffable' do
      let(:diffable_merge_ref?) { false }

      it 'serializes target_versions using DiffTargetVersionEntity' do
        expect(RapidDiffs::DiffTargetVersionEntity).to receive(:represent)
          .with(
            [diff_3, diff_2, diff_1],
            merge_request: merge_request,
            merge_request_diffs: [diff_3, diff_2, diff_1],
            diff_id: options[:diff_id],
            start_sha: options[:start_sha]
          )
          .and_call_original

        serialized
      end
    end
  end
end
