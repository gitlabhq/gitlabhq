# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Component, feature_category: :pipeline_composition do
  let(:component) { described_class.new(config) }

  describe 'validations' do
    context 'when config is an array of valid strings' do
      let(:config) { %w[name sha version reference] }

      it 'passes validations' do
        expect(component).to be_valid
        expect(component.errors).to be_empty
      end
    end

    context 'when config is an empty array' do
      let(:config) { [] }

      it 'passes validations' do
        expect(component).to be_valid
        expect(component.errors).to be_empty
      end
    end

    context 'when config contains invalid values' do
      let(:config) { %w[name invalid_key version] }

      it 'fails validations' do
        expect(component).not_to be_valid
        expect(component.errors).to include(/component config contains unknown values: invalid_key/)
      end
    end

    context 'when config is not an array' do
      let(:config) { 'name' }

      it 'fails validations' do
        expect(component).not_to be_valid
        expect(component.errors).to include(/component config should be an array/)
      end
    end

    context 'when config is a hash' do
      let(:config) { { name: true } }

      it 'fails validations' do
        expect(component).not_to be_valid
        expect(component.errors).to include(/component config should be an array/)
      end
    end

    context 'when config contains non-string values' do
      let(:config) { ['name', 123, 'version'] }

      it 'fails validations' do
        expect(component).not_to be_valid
        expect(component.errors).to include(/component config should be an array of strings/)
      end
    end
  end

  describe '#value' do
    subject(:value) { component.value }

    context 'when config is valid' do
      let(:config) { %w[name sha version reference] }

      it { is_expected.to match_array([:name, :sha, :version, :reference]) }
    end

    context 'when config has duplicate values' do
      let(:config) { %w[name version name sha] }

      it { is_expected.to match_array([:name, :version, :sha]) }
    end

    context 'when config has invalid values' do
      let(:config) { %w[name version invalid] }

      it { is_expected.to be_empty }
    end

    context 'when config is empty array' do
      let(:config) { [] }

      it { is_expected.to be_empty }
    end

    context 'when config is not an array' do
      let(:config) { 'invalid' }

      it { is_expected.to be_empty }
    end

    context 'when config is nil' do
      let(:config) { nil }

      it { is_expected.to be_empty }
    end
  end
end
