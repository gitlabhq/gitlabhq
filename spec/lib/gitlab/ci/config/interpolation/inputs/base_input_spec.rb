# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Inputs::BaseInput, feature_category: :pipeline_composition do
  describe '.matches?' do
    it 'is not implemented' do
      expect { described_class.matches?(double) }.to raise_error(NotImplementedError)
    end
  end

  describe '.type_name' do
    it 'is not implemented' do
      expect { described_class.type_name }.to raise_error(NotImplementedError)
    end
  end

  describe '#valid_value?' do
    it 'is not implemented' do
      expect do
        described_class.new(
          name: 'website', spec: { website: nil }, value: { website: 'example.com' }
        ).valid_value?('test')
      end.to raise_error(NotImplementedError)
    end
  end
end
