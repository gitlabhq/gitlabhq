# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::MergeRequestBuilder do
  let_it_be(:merge_request) { create(:merge_request) }

  let(:builder) { described_class.new(merge_request) }

  describe '.safe_hook_attributes' do
    let(:safe_attribute_keys) { described_class.safe_hook_attributes }

    it 'includes safe attribute' do
      expected_safe_attribute_keys = %i[
        assignee_id
        author_id
        blocking_discussions_resolved
        created_at
        description
        head_pipeline_id
        id
        iid
        last_edited_at
        last_edited_by_id
        merge_commit_sha
        merge_error
        merge_params
        merge_status
        merge_user_id
        merge_when_pipeline_succeeds
        milestone_id
        reviewer_ids
        source_branch
        source_project_id
        state_id
        target_branch
        target_project_id
        time_estimate
        title
        updated_at
        updated_by_id
        draft
        prepared_at
      ].freeze

      expect(safe_attribute_keys).to match_array(expected_safe_attribute_keys)
    end
  end

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
      expect(data).to include(*described_class.safe_hook_attributes)
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
        first_contribution
        detailed_merge_status
      ].freeze

      expect(data).to include(*expected_additional_attributes)
    end

    context 'when the MR has an image in the description' do
      let(:mr_with_description) { create(:merge_request, description: 'test![MR_Image](/uploads/abc/MR_Image.png)') }
      let(:builder) { described_class.new(mr_with_description) }

      it 'sets the image to use an absolute URL' do
        expected_path = "#{mr_with_description.project.path_with_namespace}/uploads/abc/MR_Image.png"

        expect(data[:description])
          .to eq("test![MR_Image](#{Settings.gitlab.url}/#{expected_path})")
      end
    end
  end
end
