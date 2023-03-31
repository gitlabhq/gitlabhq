# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Input::Arguments::Required, feature_category: :pipeline_composition do
  it 'returns a user-provided value if it is present' do
    argument = described_class.new(:website, nil, 'https://example.gitlab.com')

    expect(argument).to be_valid
    expect(argument.to_value).to eq 'https://example.gitlab.com'
    expect(argument.to_hash).to eq({ website: 'https://example.gitlab.com' })
  end

  it 'returns an empty value if user-provider value is empty' do
    argument = described_class.new(:website, nil, '')

    expect(argument).to be_valid
    expect(argument.to_hash).to eq(website: '')
  end

  it 'returns an error if user-provided value is unspecified' do
    argument = described_class.new(:website, nil, nil)

    expect(argument).not_to be_valid
    expect(argument.errors.first).to eq '`website` input: required value has not been provided'
  end

  describe '.matches?' do
    it 'matches specs without configuration' do
      expect(described_class.matches?(nil)).to be true
    end

    it 'matches specs with empty configuration' do
      expect(described_class.matches?('')).to be true
    end

    it 'matches specs with an empty hash configuration' do
      expect(described_class.matches?({})).to be true
    end

    it 'does not match specs with configuration' do
      expect(described_class.matches?({ options: %w[a b] })).to be false
    end
  end
end
