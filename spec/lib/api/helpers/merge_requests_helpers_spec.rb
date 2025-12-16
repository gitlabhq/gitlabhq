# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::MergeRequestsHelpers, feature_category: :code_review_workflow do
  let(:helper_class) do
    Class.new do
      include API::Helpers::MergeRequestsHelpers

      attr_accessor :access_token

      def initialize(token = nil)
        @access_token = token
      end
    end
  end

  let(:helper) { helper_class.new(access_token) }
  let(:access_token) { nil }

  describe '#handle_merge_request_errors!' do
    let(:merge_request) { double }

    context 'when merge request is valid' do
      it 'returns nil' do
        allow(merge_request).to receive(:valid?).and_return(true)

        expect(merge_request).not_to receive(:errors)

        helper.handle_merge_request_errors!(merge_request)
      end
    end

    context 'when merge request is invalid' do
      before do
        allow(merge_request).to receive(:valid?).and_return(false)
        allow(helper).to receive_messages([:unprocessable_entity!, :conflict!, :render_validation_error!])
      end

      API::Helpers::MergeRequestsHelpers::UNPROCESSABLE_ERROR_KEYS.each do |error_key|
        it "responds to a #{error_key} error with unprocessable_entity" do
          error = double
          allow(merge_request).to receive(:errors).and_return({ error_key => error })

          expect(helper).to receive(:unprocessable_entity!).with(error)

          helper.handle_merge_request_errors!(merge_request)
        end
      end

      it 'responds to a validate_branches error with conflict' do
        error = double
        allow(merge_request).to receive(:errors).and_return({ validate_branches: error })

        expect(helper).to receive(:conflict!).with(error)

        helper.handle_merge_request_errors!(merge_request)
      end

      it 'responds with bad request' do
        error = double
        allow(merge_request).to receive(:errors).and_return({ other_error: error })

        expect(helper).to receive(:render_validation_error!).with(merge_request)

        helper.handle_merge_request_errors!(merge_request)
      end
    end
  end

  describe '#filter_diffs_for_mcp' do
    let(:diffs) { [instance_double(Gitlab::Git::Diff), instance_double(Gitlab::Git::Diff)] }

    it 'returns diffs unchanged' do
      result = helper.filter_diffs_for_mcp(diffs, nil)

      expect(result).to eq(diffs)
    end
  end
end
