# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Input::Arguments::Default, feature_category: :pipeline_composition do
  it 'returns a user-provided value if it is present' do
    argument = described_class.new(:website, { default: 'https://gitlab.com' }, 'https://example.gitlab.com')

    expect(argument).to be_valid
    expect(argument.to_value).to eq 'https://example.gitlab.com'
    expect(argument.to_hash).to eq({ website: 'https://example.gitlab.com' })
  end

  it 'returns an empty value if user-provider input is empty' do
    argument = described_class.new(:website, { default: 'https://gitlab.com' }, '')

    expect(argument).to be_valid
    expect(argument.to_value).to eq ''
    expect(argument.to_hash).to eq({ website: '' })
  end

  it 'returns a default value if user-provider one is unknown' do
    argument = described_class.new(:website, { default: 'https://gitlab.com' }, nil)

    expect(argument).to be_valid
    expect(argument.to_value).to eq 'https://gitlab.com'
    expect(argument.to_hash).to eq({ website: 'https://gitlab.com' })
  end

  it 'returns an error if the default argument has not been recognized' do
    argument = described_class.new(:website, { default: ['gitlab.com'] }, 'abc')

    expect(argument).not_to be_valid
  end

  it 'returns an error if the argument has not been fabricated correctly' do
    argument = described_class.new(:website, { required: 'https://gitlab.com' }, 'https://example.gitlab.com')

    expect(argument).not_to be_valid
  end

  describe '.matches?' do
    it 'matches specs with default configuration' do
      expect(described_class.matches?({ default: 'abc' })).to be true
    end

    it 'does not match specs different configuration keyword' do
      expect(described_class.matches?({ options: %w[a b] })).to be false
      expect(described_class.matches?('a b c')).to be false
      expect(described_class.matches?(%w[default a])).to be false
    end
  end
end
