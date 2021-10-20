# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::Mergeability::ResultsStore do
  subject(:results_store) { described_class.new(merge_request: merge_request, interface: interface) }

  let(:merge_check) { double }
  let(:interface) { double }
  let(:merge_request) { double }

  describe '#read' do
    it 'calls #retrieve on the interface' do
      expect(interface).to receive(:retrieve_check).with(merge_check: merge_check)

      results_store.read(merge_check: merge_check)
    end
  end

  describe '#write' do
    let(:result_hash) { double }

    it 'calls #save_check on the interface' do
      expect(interface).to receive(:save_check).with(merge_check: merge_check, result_hash: result_hash)

      results_store.write(merge_check: merge_check, result_hash: result_hash)
    end
  end
end
