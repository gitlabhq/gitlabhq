# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml, feature_category: :pipeline_composition do
  describe '.load!' do
    context 'with basic YAML' do
      let(:yaml) do
        <<~YAML
        image: 'image:1.0'
        texts:
          nested_key: 'value1'
          more_text:
            more_nested_key: 'value2'
        YAML
      end

      subject(:config) { described_class.load!(yaml) }

      it 'loads a YAML file' do
        expect(config).to eq({
          image: 'image:1.0',
          texts: {
            nested_key: 'value1',
            more_text: {
              more_nested_key: 'value2'
            }
          }
        })
      end

      context 'when YAML is invalid' do
        let(:yaml) { 'some: invalid: syntax' }

        it 'raises an error' do
          expect { config }
            .to raise_error ::Gitlab::Config::Loader::FormatError, /mapping values are not allowed in this context/
        end
      end
    end

    context 'with inputs and variables' do
      let(:yaml) do
        <<~YAML
        spec:
          inputs:
            compiler:
              default: gcc
            optimization_level:
              type: number
              default: 0
        ---

        test:
          script:
            - echo "with compiler $[[ inputs.compiler | expand_vars ]] and level $[[ inputs.optimization_level ]]"
        YAML
      end

      let(:inputs) do
        { compiler: 'g++', optimization_level: 1 }
      end

      let(:variables) do
        [{ key: 'COMPILER', value: 'c++' }]
      end

      subject(:config) { described_class.load!(yaml, inputs, variables) }

      it 'loads a YAML file with inputs' do
        expect(config).to eq(
          test: {
            script: ['echo "with compiler g++ and level 1"']
          }
        )
      end

      context 'when using a variable in the input value' do
        let(:inputs) do
          { compiler: '$COMPILER', optimization_level: 2 }
        end

        it 'loads the YAML config file, expands the variable and interpolates the input(s)' do
          expect(config).to eq(
            test: {
              script: ['echo "with compiler c++ and level 2"']
            }
          )
        end
      end

      context 'when given invalid input values' do
        let(:inputs) do
          { compiler: 5, optimization_level: 'a string' }
        end

        it 'raises error' do
          expect { config }.to raise_error(
            ::Gitlab::Ci::Config::Yaml::LoadError,
            '`compiler` input: provided value is not a string, ' \
              '`optimization_level` input: provided value is not a number'
          )
        end
      end

      context 'with default parameters' do
        subject(:config) { described_class.load!(yaml) }

        it 'works with empty inputs and variables' do
          expect(config).to eq(
            test: {
              script: ['echo "with compiler gcc and level 0"']
            }
          )
        end
      end

      context 'with only inputs' do
        subject(:config) { described_class.load!(yaml, { compiler: 'clang', optimization_level: 3 }) }

        it 'works with only inputs parameter' do
          expect(config).to eq(
            test: {
              script: ['echo "with compiler clang and level 3"']
            }
          )
        end
      end
    end
  end
end
