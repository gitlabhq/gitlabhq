require 'spec_helper'

describe Github::Import::LegacyDiffNote do
  describe '#type' do
    it 'returns the original note type' do
      expect(described_class.new.type).to eq('LegacyDiffNote')
    end
  end
end
