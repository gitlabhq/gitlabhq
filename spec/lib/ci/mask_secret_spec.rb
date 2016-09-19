require 'spec_helper'

describe Ci::MaskSecret, lib: true do
  subject { described_class }

  describe '#mask' do
    it 'masks exact number of characters' do
      expect(subject.mask('token', 'oke')).to eq('txxxn')
    end

    it 'masks multiple occurrences' do
      expect(subject.mask('token token token', 'oke')).to eq('txxxn txxxn txxxn')
    end

    it 'does not mask if not found' do
      expect(subject.mask('token', 'not')).to eq('token')
    end
  end
end
