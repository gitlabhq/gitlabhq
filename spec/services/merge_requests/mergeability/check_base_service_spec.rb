# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckBaseService, feature_category: :code_review_workflow do
  subject(:check_base_service) { described_class.new(merge_request: merge_request, params: params) }

  let(:merge_request) { double }
  let(:params) { double }

  describe '#merge_request' do
    it 'returns the merge_request' do
      expect(check_base_service.merge_request).to eq merge_request
    end
  end

  describe '#params' do
    it 'returns the params' do
      expect(check_base_service.params).to eq params
    end
  end

  describe '#skip?' do
    it 'raises NotImplementedError' do
      expect { check_base_service.skip? }.to raise_error(NotImplementedError)
    end
  end

  describe '#cacheable?' do
    it 'raises NotImplementedError' do
      expect { check_base_service.skip? }.to raise_error(NotImplementedError)
    end
  end

  describe '#cache_key?' do
    it 'raises NotImplementedError' do
      expect { check_base_service.skip? }.to raise_error(NotImplementedError)
    end
  end
end
