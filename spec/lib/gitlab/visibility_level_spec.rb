require 'spec_helper'

describe Gitlab::VisibilityLevel, lib: true do
  describe '.level_value' do
    it 'converts "public" to integer value' do
      expect(described_class.level_value('public')).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'converts string integer to integer value' do
      expect(described_class.level_value('20')).to eq(20)
    end

    it 'defaults to PRIVATE when string value is not valid' do
      expect(described_class.level_value('invalid')).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'defaults to PRIVATE when integer value is not valid' do
      expect(described_class.level_value(100)).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end
end
