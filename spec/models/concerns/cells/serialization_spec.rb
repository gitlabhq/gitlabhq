# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::Serialization, feature_category: :cell do
  describe '.to_bytes' do
    subject(:to_bytes) { described_class.to_bytes(value) }

    context 'when value is an Integer' do
      let(:value) { 42 }

      it 'encodes as uint64 big-endian' do
        expect(to_bytes).to eq([42].pack("Q>"))
      end

      it 'is decodable back to the original integer' do
        expect(to_bytes.unpack1("Q>")).to eq(value)
      end

      context 'when value is 0' do
        let(:value) { 0 }

        it 'encodes correctly' do
          expect(to_bytes.unpack1("Q>")).to eq(0)
        end
      end

      context 'when value is a large integer' do
        let(:value) { (2**63) - 1 }

        it 'encodes correctly' do
          expect(to_bytes.unpack1("Q>")).to eq(value)
        end
      end
    end

    context 'when value is a UUID string' do
      let(:value) { SecureRandom.uuid }

      it 'encodes as hex bytes without dashes' do
        expect(to_bytes).to eq([value.delete("-")].pack("H*"))
      end

      it 'is decodable back to the original UUID' do
        # Rebuild UUID from hex: 8-4-4-4-12
        hex = to_bytes.unpack1("H*")
        rebuilt = [hex[0..7], hex[8..11], hex[12..15], hex[16..19], hex[20..31]].join("-")
        expect(rebuilt).to eq(value)
      end

      it 'returns a binary string' do
        expect(to_bytes.encoding).to eq(Encoding::ASCII_8BIT)
      end
    end

    context 'when value is a plain string (non-UUID)' do
      let(:value) { 'some-plain-key' }

      it 'returns the string as-is' do
        expect(to_bytes).to eq(value)
      end
    end

    context 'when value is an unsupported type' do
      [nil, 1.5, [], {}].each do |unsupported|
        context "when value is #{unsupported.inspect}" do
          let(:value) { unsupported }

          it 'raises ArgumentError' do
            expect { to_bytes }.to raise_error(ArgumentError, /Unsupported primary key type/)
          end
        end
      end
    end
  end
end
