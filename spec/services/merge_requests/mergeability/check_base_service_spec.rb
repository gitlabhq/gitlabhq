# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckBaseService, feature_category: :code_review_workflow do
  subject(:check_base_service) { described_class.new(merge_request: merge_request, params: params) }

  let(:merge_request) { double }
  let(:params) { double }

  describe '.identifier' do
    it 'sets the identifier' do
      described_class.set_identifier("test")

      expect(described_class.identifier).to eq("test")
    end
  end

  describe '.description' do
    it 'sets the description' do
      described_class.set_description("test")

      expect(described_class.description).to eq("test")
    end
  end

  describe '.failure_explanation' do
    it 'sets the failure explanation' do
      described_class.set_failure_explanation("test")

      expect(described_class.failure_explanation).to eq("test")
    end
  end

  describe 'every mergeability check' do
    it 'defines a failure explanation' do
      checks_without_explanation = MergeRequest.all_mergeability_checks.reject(&:failure_explanation)

      expect(checks_without_explanation).to be_empty,
        "Expected every mergeability check to define a failure explanation via " \
          "`set_failure_explanation`, but these do not: " \
          "#{checks_without_explanation.map(&:identifier).inspect}"
    end
  end

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
