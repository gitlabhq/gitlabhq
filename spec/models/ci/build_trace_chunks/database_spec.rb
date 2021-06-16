# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunks::Database do
  let(:data_store) { described_class.new }

  describe '#data' do
    subject { data_store.data(model) }

    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :database_with_data, initial_data: 'sample data in database') }

      it 'returns the data' do
        is_expected.to eq('sample data in database')
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :database_without_data) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#set_data' do
    subject { data_store.set_data(model, data) }

    let(:data) { 'abc123' }

    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :database_with_data, initial_data: 'sample data in database') }

      it 'overwrites data' do
        expect(data_store.data(model)).to eq('sample data in database')

        subject

        expect(data_store.data(model)).to eq('abc123')
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :database_without_data) }

      it 'sets new data' do
        expect(data_store.data(model)).to be_nil

        subject

        expect(data_store.data(model)).to eq('abc123')
      end
    end
  end

  describe '#delete_data' do
    subject { data_store.delete_data(model) }

    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :database_with_data, initial_data: 'sample data in database') }

      it 'deletes data' do
        expect(data_store.data(model)).to eq('sample data in database')

        subject

        expect(data_store.data(model)).to be_nil
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :database_without_data) }

      it 'does nothing' do
        expect(data_store.data(model)).to be_nil

        subject

        expect(data_store.data(model)).to be_nil
      end
    end
  end

  describe '#size' do
    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :database_with_data, initial_data: 'üabcdef') }

      it 'returns data bytesize correctly' do
        expect(data_store.size(model)).to eq 8
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :database_without_data) }

      it 'returns zero' do
        expect(data_store.size(model)).to be_zero
      end
    end
  end

  describe '#keys' do
    subject { data_store.keys(relation) }

    let(:build) { create(:ci_build) }
    let(:relation) { build.trace_chunks }

    before do
      create(:ci_build_trace_chunk, :database_with_data, chunk_index: 0, build: build)
      create(:ci_build_trace_chunk, :database_with_data, chunk_index: 1, build: build)
    end

    it 'returns empty array' do
      is_expected.to eq([])
    end
  end
end
