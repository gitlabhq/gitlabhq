require 'spec_helper'

describe Github::Import::Note do
  describe '#type' do
    it 'returns the original note type' do
      expect(described_class.new.type).to eq('Note')
    end
  end
end
