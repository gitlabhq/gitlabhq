# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Include, feature_category: :pipeline_composition do
  let(:factory) { Gitlab::Config::Entry::Factory.new(described_class).value(config) }
  let(:include_entry) { factory.create!.tap(&:compose!) }

  subject(:config_entry) { include_entry }

  # Test all common include validations shared with Entry::Include
  it_behaves_like 'basic include validations'
  it_behaves_like 'integrity validation for includes'

  # Header::Include specific tests
  context 'when include contains unknown keywords specific to Entry::Include' do
    let(:config) { { local: 'path/to/file.yml', template: 'template.yml' } }

    it 'fails validations' do
      expect(include_entry).not_to be_valid
      expect(include_entry.errors).to include('include config contains unknown keys: template')
    end
  end

  context 'when include is an array' do
    let(:config) { %w[value1 value2] }

    it 'fails validations' do
      expect(include_entry).not_to be_valid
      expect(include_entry.errors).to eq(['include config should be a hash or a string'])
    end

    it 'returns the value' do
      expect(include_entry.value).to eq(config)
    end
  end

  describe '#value' do
    context 'when config is a string' do
      let(:config) { 'test.yml' }

      it 'returns the string value' do
        expect(include_entry.value).to eq('test.yml')
      end
    end

    context 'when config is a hash' do
      let(:config) { { local: 'test.yml' } }

      it 'returns the hash value' do
        expect(include_entry.value).to eq({ local: 'test.yml' })
      end
    end
  end
end
