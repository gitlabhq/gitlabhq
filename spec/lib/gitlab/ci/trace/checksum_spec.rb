# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Trace::Checksum do
  let(:build) { create(:ci_build, :running) }

  subject { described_class.new(build) }

  context 'when build pending state exists' do
    let(:trace_details) do
      { trace_checksum: 'crc32:d4777540', trace_bytesize: 262161 }
    end

    before do
      create(:ci_build_pending_state, build: build, **trace_details)
    end

    context 'when matching persisted trace chunks exist' do
      before do
        create_chunk(index: 0, data: 'a' * 128.kilobytes)
        create_chunk(index: 1, data: 'b' * 128.kilobytes)
        create_chunk(index: 2, data: 'ccccccccccccccccc')
      end

      it 'calculates combined trace chunks CRC32 correctly' do
        expect(subject.chunks_crc32).to eq 3564598592
        expect(subject).to be_valid
        expect(subject).not_to be_corrupted
      end
    end

    context 'when trace chunks were persisted in a wrong order' do
      before do
        create_chunk(index: 0, data: 'b' * 128.kilobytes)
        create_chunk(index: 1, data: 'a' * 128.kilobytes)
        create_chunk(index: 2, data: 'ccccccccccccccccc')
      end

      it 'makes trace checksum invalid but not corrupted' do
        expect(subject).not_to be_valid
        expect(subject).not_to be_corrupted
      end
    end

    context 'when one of the trace chunks is missing' do
      before do
        create_chunk(index: 0, data: 'a' * 128.kilobytes)
        create_chunk(index: 2, data: 'ccccccccccccccccc')
      end

      it 'makes trace checksum invalid and corrupted' do
        expect(subject).not_to be_valid
        expect(subject).to be_corrupted
      end
    end

    context 'when checksums of persisted trace chunks do not match' do
      before do
        create_chunk(index: 0, data: 'a' * 128.kilobytes)
        create_chunk(index: 1, data: 'X' * 128.kilobytes)
        create_chunk(index: 2, data: 'ccccccccccccccccc')
      end

      it 'makes trace checksum invalid but not corrupted' do
        expect(subject).not_to be_valid
        expect(subject).not_to be_corrupted
      end
    end

    context 'when persisted trace chunks are missing' do
      it 'makes trace checksum invalid' do
        expect(subject.state_crc32).to eq 3564598592
        expect(subject).not_to be_valid
      end
    end
  end

  context 'when build pending state is missing' do
    describe '#state_crc32' do
      it 'returns nil' do
        expect(subject.state_crc32).to be_nil
      end
    end

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end
  end

  describe '#trace_chunks' do
    before do
      create_chunk(index: 0, data: 'abcdefg')
    end

    it 'does not load raw_data from a database store' do
      subject.trace_chunks.first.then do |chunk|
        expect(chunk).to be_database
        expect { chunk.raw_data }
          .to raise_error ActiveModel::MissingAttributeError
      end
    end
  end

  describe '#last_chunk' do
    context 'when there are no chunks' do
      it 'returns nil' do
        expect(subject.last_chunk).to be_nil
      end

      it 'is not a valid trace' do
        expect(subject).not_to be_valid
      end

      it 'is not a corrupted trace' do
        expect(subject).not_to be_corrupted
      end
    end

    context 'when there are multiple chunks' do
      before do
        create_chunk(index: 1, data: '1234')
        create_chunk(index: 0, data: 'abcd')
      end

      it 'returns chunk with the highest index' do
        expect(subject.last_chunk.chunk_index).to eq 1
      end

      it 'is not a valid trace' do
        expect(subject).not_to be_valid
      end

      it 'is not a corrupted trace' do
        expect(subject).not_to be_corrupted
      end
    end
  end

  describe '#trace_size' do
    before do
      create_chunk(index: 0, data: 'a' * 128.kilobytes)
      create_chunk(index: 1, data: 'b' * 128.kilobytes)
      create_chunk(index: 2, data: 'abcdefg-ü')
    end

    it 'returns total trace size in bytes' do
      expect(subject.trace_size).to eq 262154
    end
  end

  def create_chunk(index:, data:)
    create(:ci_build_trace_chunk, :persisted, build: build, chunk_index: index, initial_data: data)
  end
end
