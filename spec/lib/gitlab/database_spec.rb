require 'spec_helper'

describe Gitlab::Database do
  # These are just simple smoke tests to check if the methods work (regardless
  # of what they may return).
  describe '.mysql?' do
    subject { described_class.mysql? }

    it { is_expected.to satisfy { |val| val == true || val == false } }
  end

  describe '.postgresql?' do
    subject { described_class.postgresql? }

    it { is_expected.to satisfy { |val| val == true || val == false } }
  end
end
