# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Root, feature_category: :pipeline_composition do
  let(:factory) { Gitlab::Config::Entry::Factory.new(described_class).value(header_hash) }

  subject(:config) { factory.create!.tap(&:compose!) }

  shared_examples 'a valid header' do
    let(:expected_hash) { header_hash }

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns the value' do
      expect(config.value).to eq(expected_hash)
    end
  end

  shared_examples 'an invalid header' do
    let(:expected_hash) { header_hash }

    it 'fails validations' do
      expect(config).not_to be_valid
      expect(config.errors).to eq(expected_errors)
    end

    it 'returns the value' do
      expect(config.value).to eq(expected_hash)
    end
  end

  context 'when header contains default and required values for inputs' do
    let(:header_hash) do
      {
        spec: {
          inputs: {
            test: {},
            foo: {
              default: 'bar'
            }
          }
        }
      }
    end

    it_behaves_like 'a valid header'
  end

  context 'when header contains minimal data' do
    let(:header_hash) do
      {
        spec: {
          inputs: nil
        }
      }
    end

    it_behaves_like 'a valid header' do
      let(:expected_hash) { { spec: {} } }
    end
  end

  context 'when header contains required inputs' do
    let(:header_hash) do
      {
        spec: {
          inputs: { foo: nil }
        }
      }
    end

    it_behaves_like 'a valid header' do
      let(:expected_hash) do
        {
          spec: {
            inputs: { foo: {} }
          }
        }
      end
    end
  end

  context 'when header contains unknown keywords' do
    let(:header_hash) { { test: 123 } }
    let(:expected_errors) { ['root config contains unknown keys: test'] }

    it_behaves_like 'an invalid header'
  end

  context 'when header input entry has an unknown key' do
    let(:header_hash) do
      {
        spec: {
          inputs: {
            foo: {
              bad: 'value'
            }
          }
        }
      }
    end

    let(:expected_errors) { ['spec:inputs:foo config contains unknown keys: bad'] }

    it_behaves_like 'an invalid header'
  end

  describe '#spec_inputs_value' do
    let(:header_hash) do
      {
        spec: {
          inputs: {
            foo: nil,
            bar: {
              default: 'baz'
            }
          }
        }
      }
    end

    it 'returns the inputs' do
      expect(config.spec_inputs_value).to eq({
        foo: {},
        bar: { default: 'baz' }
      })
    end
  end

  describe '#spec_component_value' do
    context 'when component is specified' do
      let(:header_hash) do
        {
          spec: {
            component: %w[name sha version]
          }
        }
      end

      it 'returns the component value as symbols' do
        expect(config.spec_component_value).to match_array([:name, :sha, :version])
      end
    end

    context 'when component is empty' do
      let(:header_hash) do
        {
          spec: {
            component: []
          }
        }
      end

      it 'returns empty array' do
        expect(config.spec_component_value).to be_empty
      end
    end

    context 'when component is not specified' do
      let(:header_hash) do
        {
          spec: {
            inputs: {
              foo: { default: 'bar' }
            }
          }
        }
      end

      it 'returns empty array by default' do
        expect(config.spec_component_value).to be_empty
      end
    end

    context 'when both inputs and component are specified' do
      let(:header_hash) do
        {
          spec: {
            inputs: {
              foo: { default: 'bar' }
            },
            component: %w[name version]
          }
        }
      end

      it 'returns both values correctly' do
        expect(config.spec_inputs_value).to eq({ foo: { default: 'bar' } })
        expect(config.spec_component_value).to match_array([:name, :version])
      end
    end
  end
end
