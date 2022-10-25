# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::MergeRequests::Mergeability::ResultsStore do
  subject(:results_store) { described_class.new(merge_request: merge_request, interface: interface) }

  let(:merge_check) { double }
  let(:interface) { double }
  let(:merge_request) { double }

  describe '#read' do
    let(:result_hash) { { status: 'success', payload: {} } }

    it 'calls #retrieve_check on the interface' do
      expect(interface).to receive(:retrieve_check).with(merge_check: merge_check).and_return(result_hash)

      cached_result = results_store.read(merge_check: merge_check)

      expect(cached_result.status).to eq(result_hash[:status].to_sym)
      expect(cached_result.payload).to eq(result_hash[:payload])
    end

    context 'when #retrieve_check returns nil' do
      it 'returns nil' do
        expect(interface).to receive(:retrieve_check).with(merge_check: merge_check).and_return(nil)
        expect(results_store.read(merge_check: merge_check)).to be_nil
      end
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
