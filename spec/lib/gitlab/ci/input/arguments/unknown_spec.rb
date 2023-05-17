# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Input::Arguments::Unknown, feature_category: :pipeline_composition do
  it 'raises an error when someone tries to evaluate the value' do
    argument = described_class.new(:website, nil, 'https://example.gitlab.com')

    expect(argument).not_to be_valid
    expect { argument.to_value }.to raise_error ArgumentError
  end

  describe '.matches?' do
    it 'always matches' do
      expect(described_class.matches?('abc')).to be true
    end
  end
end
