require 'rails_helper'

describe MergeRequestDiffFile do
  describe '#diff' do
    let(:unpacked) { 'unpacked' }
    let(:packed) { [unpacked].pack('m0') }

    before do
      subject.diff = packed
    end

    context 'when the diff is marked as binary' do
      before do
        subject.binary = true
      end

      it 'unpacks from base 64' do
        expect(subject.diff).to eq(unpacked)
      end
    end

    context 'when the diff is not marked as binary' do
      it 'returns the raw diff' do
        expect(subject.diff).to eq(packed)
      end
    end
  end

  describe '#utf8_diff' do
    it 'does not raise error when the diff is binary' do
      subject.diff = "\x05\x00\x68\x65\x6c\x6c\x6f"

      expect { subject.utf8_diff }.not_to raise_error
    end
  end
end
