# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::NotesHelpers, feature_category: :api do
  describe '.job_token_policy_for' do
    let(:noteable_type_with_policy) do
      instance_double(API::Helpers::NotesHelpers::NoteableType, policy_base: 'merge_requests')
    end

    context 'when noteable_type has a policy_base' do
      context 'when http_method is GET' do
        it 'returns read policy symbol' do
          result = described_class.job_token_policy_for(noteable_type_with_policy, 'GET')

          expect(result).to eq(:read_merge_requests)
        end
      end

      context 'when http_method is HEAD' do
        it 'returns read policy symbol' do
          result = described_class.job_token_policy_for(noteable_type_with_policy, 'HEAD')

          expect(result).to eq(:read_merge_requests)
        end
      end

      context 'when http_method is POST' do
        it 'raises ArgumentError for non-read operations' do
          expect do
            described_class.job_token_policy_for(noteable_type_with_policy, 'POST')
          end.to raise_error(ArgumentError, 'Job tokens only support read operations')
        end
      end
    end

    context 'when noteable_type is nil' do
      it 'returns nil' do
        result = described_class.job_token_policy_for(nil, 'GET')

        expect(result).to be_nil
      end
    end

    context 'when noteable_type has nil policy_base' do
      let(:noteable_type_with_nil_policy) do
        instance_double(API::Helpers::NotesHelpers::NoteableType, policy_base: nil)
      end

      it 'returns nil' do
        result = described_class.job_token_policy_for(noteable_type_with_nil_policy, 'GET')

        expect(result).to be_nil
      end
    end

    context 'when http_method is nil' do
      it 'returns nil' do
        result = described_class.job_token_policy_for(noteable_type_with_policy, nil)

        expect(result).to be_nil
      end
    end
  end

  describe API::Helpers::NotesHelpers::NoteableType do
    describe '#human_name' do
      using RSpec::Parameterized::TableSyntax

      where(:class_name, :expected_human_name) do
        'MergeRequest'       | 'merge request'
        'Issue'              | 'issue'
        'WikiPage::Meta'     | 'wiki page meta'
        'APIResource'        | 'api resource'
      end

      with_them do
        it 'converts class name to human readable format' do
          mock_class = instance_double(Class, to_s: class_name)

          noteable_type = described_class.new(
            noteable_class: mock_class,
            feature_category: :code_review_workflow,
            parent_type: 'project'
          )

          expect(noteable_type.human_name).to eq(expected_human_name)
        end
      end
    end
  end
end
