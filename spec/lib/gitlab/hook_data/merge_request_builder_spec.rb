# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::MergeRequestBuilder, feature_category: :code_review_workflow do
  let_it_be(:merge_request, freeze: false) { create(:merge_request) }

  let(:builder) { described_class.new(merge_request) }

  describe '#build' do
    let(:data) { builder.build }

    %i[source target].each do |key|
      describe "#{key} key" do
        include_examples 'project hook data', project_key: key do
          let(:project) { merge_request.public_send("#{key}_project") }
        end
      end
    end

    it 'includes safe attributes' do
      expected_attributes = described_class.safe_hook_attributes.reject { |attr| attr == :system_action }
      expect(data).to include(*expected_attributes)
      expect(data).to include(:system) # system should always be present
      # system_action is only included when not nil, so we don't test for its presence here
    end

    it 'includes system in safe hook attributes' do
      expect(described_class.safe_hook_attributes).to include(:system)
    end

    it 'includes additional attrs' do
      expected_additional_attributes = %w[
        description
        url
        last_commit
        work_in_progress
        draft
        total_time_spent
        time_change
        human_total_time_spent
        human_time_change
        human_time_estimate
        assignee_ids
        assignee_id
        reviewer_ids
        labels
        state
        blocking_discussions_resolved
        target_branch
        first_contribution
        detailed_merge_status
        merged_at
      ].freeze

      expect(data).to include(*expected_additional_attributes)
    end

    context 'when the MR is merged' do
      let_it_be(:merged_mr) { create(:merge_request, :merged) }
      let(:builder) { described_class.new(merged_mr) }

      it 'includes merged_at from metrics' do
        expect(data[:merged_at]).to eq(merged_mr.metrics.merged_at)
      end
    end

    context 'when the MR is not merged' do
      it 'includes merged_at as nil' do
        expect(data[:merged_at]).to be_nil
      end
    end

    context 'when the MR has a squash commit' do
      before do
        merge_request.update_column(:squash_commit_sha, 'b83d6e391c22777fca1ed3012fce84f633d7fed0')
      end

      it 'includes squash_commit_sha' do
        expect(data[:squash_commit_sha]).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
      end
    end

    context 'when the MR has an image in the description' do
      let(:mr_with_description) { create(:merge_request, description: 'test![MR_Image](/uploads/abc/MR_Image.png)') }
      let(:builder) { described_class.new(mr_with_description) }

      it 'sets the image to use an absolute URL' do
        expected_path = "-/project/#{mr_with_description.project.id}/uploads/abc/MR_Image.png"

        expect(data[:description])
          .to eq("test![MR_Image](#{Settings.gitlab.url}/#{expected_path})")
      end
    end
  end
end
