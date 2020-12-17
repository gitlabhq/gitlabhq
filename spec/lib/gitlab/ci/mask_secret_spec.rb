# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::MaskSecret do
  subject { described_class }

  describe '#mask' do
    it 'masks exact number of characters' do
      expect(mask('token', 'oke')).to eq('txxxn')
    end

    it 'masks multiple occurrences' do
      expect(mask('token token token', 'oke')).to eq('txxxn txxxn txxxn')
    end

    it 'does not mask if not found' do
      expect(mask('token', 'not')).to eq('token')
    end

    it 'does support null token' do
      expect(mask('token', nil)).to eq('token')
    end

    it 'does not change a bytesize of a value' do
      expect(mask('token-ü/unicode', 'token-ü').bytesize).to eq 16
    end

    def mask(value, token)
      subject.mask!(value.dup, token)
    end
  end
end
