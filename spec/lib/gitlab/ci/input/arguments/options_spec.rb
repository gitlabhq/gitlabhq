# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Input::Arguments::Options, feature_category: :pipeline_composition do
  it 'returns a user-provided value if it is an allowed one' do
    argument = described_class.new(:run, { options: %w[opt1 opt2] }, 'opt1')

    expect(argument).to be_valid
    expect(argument.to_value).to eq 'opt1'
    expect(argument.to_hash).to eq({ run: 'opt1' })
  end

  it 'returns an error if user-provided value is not allowlisted' do
    argument = described_class.new(:run, { options: %w[opt1 opt2] }, 'opt3')

    expect(argument).not_to be_valid
    expect(argument.errors.first).to eq '`run` input: argument value opt3 not allowlisted'
  end

  it 'returns an error if specification is not correct' do
    argument = described_class.new(:website, { options: nil }, 'opt1')

    expect(argument).not_to be_valid
    expect(argument.errors.first).to eq '`website` input: argument specification invalid'
  end

  it 'returns an error if specification is using a hash' do
    argument = described_class.new(:website, { options: { a: 1 } }, 'opt1')

    expect(argument).not_to be_valid
    expect(argument.errors.first).to eq '`website` input: argument specification invalid'
  end

  it 'returns an empty value if it is allowlisted' do
    argument = described_class.new(:run, { options: ['opt1', ''] }, '')

    expect(argument).to be_valid
    expect(argument.to_value).to be_empty
    expect(argument.to_hash).to eq({ run: '' })
  end

  describe '.matches?' do
    it 'matches specs with options configuration' do
      expect(described_class.matches?({ options: %w[a b] })).to be true
    end

    it 'does not match specs different configuration keyword' do
      expect(described_class.matches?({ default: 'abc' })).to be false
      expect(described_class.matches?(['options'])).to be false
      expect(described_class.matches?('options')).to be false
    end
  end
end
