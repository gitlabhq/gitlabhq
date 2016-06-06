require 'spec_helper'

describe Gitlab::Ci::Config::Entry::BeforeScript do
  let(:entry) { described_class.new(hash, config) }

  describe '#leaf?' do
    it 'is a leaf entry' do
      expect(entry).to be_leaf
    end
  end
end
