# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckMergeRequestTitleRegexService, feature_category: :code_review_workflow do
  subject(:check_title_regex) { described_class.new(merge_request: merge_request, params: params) }

  let_it_be(:merge_request) { build(:merge_request) }

  let(:params) { { skip_merge_request_title_check: skip_check } }
  let(:skip_check) { false }

  it_behaves_like 'mergeability check service', :title_regex,
    'Checks whether the title matches the expected regex'

  describe '#execute' do
    let(:result) { check_title_regex.execute }

    before do
      merge_request.project.merge_request_title_regex = regex
    end

    context 'when the project does not have a regex set' do
      let(:regex) { nil }

      it 'returns a check result with status inactive' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS
        expect(result.payload[:identifier]).to eq(:title_regex)
      end
    end

    context 'when the regex is set' do
      let(:regex) { 'test1' }

      context 'when the feature flag merge_request_title_regex is off' do
        before do
          stub_feature_flags(merge_request_title_regex: false)
        end

        it 'returns a check result with status inactive' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS
          expect(result.payload[:identifier]).to eq(:title_regex)
        end
      end

      context 'when the regex does not match the title' do
        before do
          merge_request.title = 'test2'
        end

        it 'returns a check result with status failed' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
          expect(result.payload[:identifier]).to eq(:title_regex)
        end
      end

      context 'when regex matches the title' do
        before do
          merge_request.title = 'test1'
        end

        it 'returns a check result with status success' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
          expect(result.payload[:identifier]).to eq(:title_regex)
        end
      end
    end
  end

  describe '#skip?' do
    context 'when skip check param is true' do
      let(:skip_check) { true }

      it 'returns true' do
        expect(check_title_regex.skip?).to be true
      end
    end

    context 'when skip check param is false' do
      let(:skip_check) { false }

      it 'returns false' do
        expect(check_title_regex.skip?).to be false
      end
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_title_regex.cacheable?).to be false
    end
  end
end
