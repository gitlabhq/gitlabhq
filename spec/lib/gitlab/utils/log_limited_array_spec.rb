# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::LogLimitedArray do
  describe '.log_limited_array' do
    context 'when the argument is not an array' do
      it 'returns an empty array' do
        expect(described_class.log_limited_array('aa')).to eq([])
      end
    end

    context 'when the argument is an array' do
      context 'when the array is under the limit' do
        it 'returns the array unchanged' do
          expect(described_class.log_limited_array(%w[a b])).to eq(%w[a b])
        end
      end

      context 'when the array exceeds the limit' do
        let(:long_array) do
          half_limit = described_class::MAXIMUM_ARRAY_LENGTH / 2

          ['a' * half_limit, 'b' * half_limit, 'c']
        end

        context 'when no sentinel value is passed' do
          it 'replaces arguments after the limit with an ellipsis string' do
            expect(described_class.log_limited_array(long_array))
              .to eq(long_array.take(1) + ['...'])
          end
        end

        context 'when a sentinel value is passed' do
          it 'replaces arguments after the limit with the sentinel' do
            sentinel = { truncated: true }

            expect(described_class.log_limited_array(long_array, sentinel: sentinel))
              .to eq(long_array.take(1) + [sentinel])
          end
        end
      end

      context 'when the array contains arrays and hashes' do
        it 'calculates the size based on the JSON representation' do
          long_array = [
            'a',
            ['b'] * 10,
            { c: 'c' * 10 },
            # Each character in the array takes up four characters: the
            # character itself, the two quotes, and the comma (closing
            # square bracket for the last item)
            ['d'] * (described_class::MAXIMUM_ARRAY_LENGTH / 4),
            'e'
          ]

          expect(described_class.log_limited_array(long_array))
            .to eq(long_array.take(3) + ['...'])
        end
      end
    end
  end
end
