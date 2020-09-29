# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildPendingState do
  describe '#crc32' do
    context 'when checksum does not exist' do
      let(:pending_state) do
        build(:ci_build_pending_state, trace_checksum: nil)
      end

      it 'returns nil' do
        expect(pending_state.crc32).to be_nil
      end
    end

    context 'when checksum is in hexadecimal' do
      let(:pending_state) do
        build(:ci_build_pending_state, trace_checksum: 'crc32:75bcd15')
      end

      it 'returns decimal representation of the checksum' do
        expect(pending_state.crc32).to eq 123456789
      end
    end
  end
end
