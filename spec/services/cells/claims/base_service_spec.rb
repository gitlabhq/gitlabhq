# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::Claims::BaseService, feature_category: :cell do
  # BaseService methods are private; use a minimal test subclass to exercise them.
  let(:test_service_class) do
    Class.new(described_class) do
      public :chunk_records, :estimate_record_size
    end
  end

  let(:service) { test_service_class.new }

  describe '#chunk_records' do
    subject(:chunks) { service.chunk_records(creates, destroys) }

    let(:small_record) { { claim: { route: 's' }, subject: { type: :user, id: 1 } } }
    let(:large_record) { { claim: { route: 'l' }, subject: { type: :user, id: 2 } } }

    before do
      stub_const("Cells::Claims::BaseService::MAX_GRPC_MESSAGE_BYTES", 1000)

      allow(service).to receive(:estimate_record_size).and_call_original
      allow(service).to receive(:estimate_record_size).with(small_record).and_return(100)
      allow(service).to receive(:estimate_record_size).with(large_record).and_return(600)
    end

    context 'when both creates and destroys are empty' do
      let(:creates) { [] }
      let(:destroys) { [] }

      it 'returns an empty array' do
        expect(chunks).to eq([])
      end
    end

    context 'when all records fit within the limit' do
      let(:creates) { [small_record, small_record] }
      let(:destroys) { [small_record] }

      it 'returns a single chunk' do
        expect(chunks.length).to eq(1)
        expect(chunks[0]).to eq([[small_record, small_record], [small_record]])
      end
    end

    context 'when creates exceed the limit' do
      let(:creates) { [large_record, large_record] }
      let(:destroys) { [] }

      it 'splits into multiple chunks' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[large_record], []])
        expect(chunks[1]).to eq([[large_record], []])
      end
    end

    context 'when destroys exceed the limit' do
      let(:creates) { [] }
      let(:destroys) { [large_record, large_record] }

      it 'splits into multiple chunks' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[], [large_record]])
        expect(chunks[1]).to eq([[], [large_record]])
      end
    end

    context 'when combined creates and destroys exceed the limit' do
      let(:creates) { [large_record] }
      let(:destroys) { [large_record] }

      it 'splits across creates and destroys' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[large_record], []])
        expect(chunks[1]).to eq([[], [large_record]])
      end
    end

    context 'when a single record exceeds the limit' do
      let(:oversized) { { claim: { route: 'o' }, subject: { type: :user, id: 3 } } }
      let(:creates) { [oversized] }
      let(:destroys) { [] }

      before do
        allow(service).to receive(:estimate_record_size).with(oversized).and_return(2000)
      end

      it 'keeps the record in its own chunk' do
        expect(chunks.length).to eq(1)
        expect(chunks[0]).to eq([[oversized], []])
      end
    end

    context 'when small records follow a large record' do
      let(:creates) { [large_record, large_record, small_record] }
      let(:destroys) { [] }

      it 'groups small records with the next large record' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[large_record], []])
        expect(chunks[1]).to eq([[large_record, small_record], []])
      end
    end

    context 'when record count exceeds MAX_RECORDS_PER_CHUNK' do
      let(:creates) { [small_record, small_record, small_record] }
      let(:destroys) { [] }

      before do
        stub_const("Cells::Claims::BaseService::MAX_RECORDS_PER_CHUNK", 2)
      end

      it 'splits into multiple chunks based on record count' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[small_record, small_record], []])
        expect(chunks[1]).to eq([[small_record], []])
      end
    end

    context 'when record count exceeds MAX_RECORDS_PER_CHUNK across creates and destroys' do
      let(:creates) { [small_record] }
      let(:destroys) { [small_record, small_record, small_record] }

      before do
        stub_const("Cells::Claims::BaseService::MAX_RECORDS_PER_CHUNK", 2)
      end

      it 'splits across both creates and destroys respecting the record cap' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[small_record], [small_record]])
        expect(chunks[1]).to eq([[], [small_record, small_record]])
      end
    end

    context 'when total size is exactly at MAX_GRPC_MESSAGE_BYTES' do
      let(:boundary_record) { { claim: { route: 'b' }, subject: { type: :user, id: 4 } } }
      let(:creates) { [boundary_record, boundary_record] }
      let(:destroys) { [] }

      before do
        # Two records totalling exactly 1000 bytes (the limit)
        allow(service).to receive(:estimate_record_size).with(boundary_record).and_return(500)
      end

      it 'fits into a single chunk' do
        expect(chunks.length).to eq(1)
        expect(chunks[0]).to eq([[boundary_record, boundary_record], []])
      end
    end

    context 'when total size is one byte over MAX_GRPC_MESSAGE_BYTES' do
      let(:just_over_record) { { claim: { route: 'j' }, subject: { type: :user, id: 5 } } }
      let(:creates) { [just_over_record, just_over_record] }
      let(:destroys) { [] }

      before do
        allow(service).to receive(:estimate_record_size).with(just_over_record).and_return(501)
      end

      it 'splits into two chunks' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[just_over_record], []])
        expect(chunks[1]).to eq([[just_over_record], []])
      end
    end

    context 'when record count is exactly at MAX_RECORDS_PER_CHUNK' do
      let(:creates) { [small_record, small_record, small_record] }
      let(:destroys) { [] }

      before do
        stub_const("Cells::Claims::BaseService::MAX_RECORDS_PER_CHUNK", 3)
      end

      it 'fits into a single chunk' do
        expect(chunks.length).to eq(1)
        expect(chunks[0]).to eq([[small_record, small_record, small_record], []])
      end
    end

    context 'when record count is one over MAX_RECORDS_PER_CHUNK' do
      let(:creates) { [small_record, small_record, small_record, small_record] }
      let(:destroys) { [] }

      before do
        stub_const("Cells::Claims::BaseService::MAX_RECORDS_PER_CHUNK", 3)
      end

      it 'splits into two chunks' do
        expect(chunks.length).to eq(2)
        expect(chunks[0]).to eq([[small_record, small_record, small_record], []])
        expect(chunks[1]).to eq([[small_record], []])
      end
    end
  end

  describe '#estimate_record_size' do
    let(:overhead) { Cells::Claims::BaseService::GRPC_PER_RECORD_OVERHEAD_BYTES }

    it 'adds the claim value bytesize to the fixed overhead' do
      record = { claim: { route: 'abc' }, subject: { type: :user, id: 1 } }

      expect(service.estimate_record_size(record)).to eq('abc'.bytesize + overhead)
    end

    it 'measures multibyte claim values by byte length' do
      record = { claim: { route: 'áé' } }

      expect(service.estimate_record_size(record)).to eq('áé'.bytesize + overhead)
    end

    it 'falls back to the overhead when the claim is missing' do
      expect(service.estimate_record_size({ subject: { type: :user, id: 1 } })).to eq(overhead)
    end
  end
end
