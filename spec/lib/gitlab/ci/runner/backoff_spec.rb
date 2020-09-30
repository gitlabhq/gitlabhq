# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'active_support/testing/time_helpers'

RSpec.describe Gitlab::Ci::Runner::Backoff do
  include ActiveSupport::Testing::TimeHelpers

  describe '#duration' do
    it 'returns backoff duration from start' do
      freeze_time do
        described_class.new(5.minutes.ago).then do |backoff|
          expect(backoff.duration).to eq 5.minutes
        end
      end
    end

    it 'returns an integer value' do
      freeze_time do
        described_class.new(5.seconds.ago).then do |backoff|
          expect(backoff.duration).to be 5
        end
      end
    end

    it 'returns the smallest number greater than or equal to duration' do
      freeze_time do
        described_class.new(0.5.seconds.ago).then do |backoff|
          expect(backoff.duration).to be 1
        end
      end
    end
  end

  describe '#slot' do
    using RSpec::Parameterized::TableSyntax

    where(:started, :slot) do
      0   | 0
      0.1 | 0
      0.9 | 0
      1   | 0
      1.1 | 0
      1.9 | 0
      2   | 0
      2.9 | 0
      3   | 0
      4   | 1
      5   | 1
      6   | 1
      7   | 1
      8   | 2
      9   | 2
      9.9 | 2
      10  | 2
      15  | 2
      16  | 3
      31  | 3
      32  | 4
      63  | 4
      64  | 5
      127 | 5
      128 | 6
      250 | 6
      310 | 7
      520 | 8
      999 | 8
    end

    with_them do
      it 'falls into an appropaite backoff slot' do
        freeze_time do
          backoff = described_class.new(started.seconds.ago)
          expect(backoff.slot).to eq slot
        end
      end
    end
  end

  describe '#to_seconds' do
    using RSpec::Parameterized::TableSyntax

    where(:started, :backoff) do
      0   | 1
      0.1 | 1
      0.9 | 1
      1   | 1
      1.1 | 1
      1.9 | 1
      2   | 1
      3   | 1
      4   | 2
      5   | 2
      6   | 2
      6.5 | 2
      7   | 2
      8   | 4
      9   | 4
      9.9 | 4
      10  | 4
      15  | 4
      16  | 8
      31  | 8
      32  | 16
      63  | 16
      64  | 32
      127 | 32
      128 | 64
      250 | 64
      310 | 64
      520 | 64
      999 | 64
    end

    with_them do
      it 'calculates backoff based on an appropriate slot' do
        freeze_time do
          described_class.new(started.seconds.ago).then do |delay|
            expect(delay.to_seconds).to eq backoff
          end
        end
      end
    end
  end
end
