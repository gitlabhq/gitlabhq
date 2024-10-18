# frozen_string_literal: true

# TODO: Change back to fast_spec_helper when removing FF
require 'spec_helper'

RSpec.describe Gitlab::Ci::MaskSecret, feature_category: :ci_variables do
  subject { described_class }

  describe '#mask' do
    it 'masks exact number of characters' do
      expect(mask('value-to-be-masked', 'be-masked')).to eq('value-to-[MASKED]x')
    end

    # This is primarily used for masked variables, which need to be eight or more characters
    # Regardless we want to ensure that this mechanism still masks in different circumstances
    it 'masks if token is shorter than eight characters' do
      expect(mask('value-to-be-masked', 'masked')).to eq('value-to-be-xxxxxx')
    end

    it 'masks multiple occurrences' do
      expect(mask('value-to-be-masked value-to-be-masked value-to-be-masked',
        'be-masked')).to eq('value-to-[MASKED]x value-to-[MASKED]x value-to-[MASKED]x')
    end

    it 'does not mask if not found' do
      expect(mask('value-to-be-masked', 'not-matching')).to eq('value-to-be-masked')
    end

    it 'does support null token' do
      expect(mask('value-to-be-masked', nil)).to eq('value-to-be-masked')
    end

    it 'does not change a bytesize of a value' do
      unicode_value = 'value-to-be-masked-ü/unicode'
      expect(mask(unicode_value, 'be-masked-ü').bytesize).to eq unicode_value.bytesize
    end

    def mask(value, token)
      subject.mask!(value.dup, token)
    end
  end
end
