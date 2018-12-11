require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Policy do
  let(:entry) { described_class.new(config) }

  describe '.default' do
    it 'does not have a default value' do
      expect(described_class.default).to be_nil
    end
  end
end
