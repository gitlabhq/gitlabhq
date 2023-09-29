# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckNotPreparingService, feature_category: :code_review_workflow do
  let(:service) { described_class.new(merge_request: merge_request, params: {}) }
  let(:merge_request) { build(:merge_request, merge_status: merge_status) }
  let(:merge_status_value) { MergeRequest.state_machines[:merge_status].states[merge_status].value }
  let(:merge_status) { :unchecked }

  describe '#execute' do
    subject(:result) { service.execute }

    it 'is success when not preparing' do
      expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
    end

    context 'when the merge request is preparing' do
      let(:merge_status) { :preparing }

      specify :aggregate_failures do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:reason]).to eq(:preparing)
      end
    end
  end

  describe '#skip?' do
    subject { service.skip? }

    it { is_expected.to eq false }
  end

  describe '#cacheable?' do
    subject { service.cacheable? }

    it { is_expected.to eq false }
  end
end
