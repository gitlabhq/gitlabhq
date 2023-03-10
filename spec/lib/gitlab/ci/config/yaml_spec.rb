# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml, feature_category: :pipeline_composition do
  describe '.load!' do
    it 'loads a single-doc YAML file' do
      yaml = <<~YAML
      image: 'image:1.0'
      texts:
        nested_key: 'value1'
        more_text:
          more_nested_key: 'value2'
      YAML

      config = described_class.load!(yaml)

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

    it 'loads the first document from a multi-doc YAML file' do
      yaml = <<~YAML
      spec:
        inputs:
          test_input:
      ---
      image: 'image:1.0'
      texts:
        nested_key: 'value1'
        more_text:
          more_nested_key: 'value2'
      YAML

      config = described_class.load!(yaml)

      expect(config).to eq({
        spec: {
          inputs: {
            test_input: nil
          }
        }
      })
    end

    context 'when YAML is invalid' do
      let(:yaml) { 'some: invalid: syntax' }

      it 'raises an error' do
        expect { described_class.load!(yaml) }
          .to raise_error ::Gitlab::Config::Loader::FormatError, /mapping values are not allowed in this context/
      end
    end

    context 'when ci_multi_doc_yaml is disabled' do
      before do
        stub_feature_flags(ci_multi_doc_yaml: false)
      end

      it 'loads a single-doc YAML file' do
        yaml = <<~YAML
        image: 'image:1.0'
        texts:
          nested_key: 'value1'
          more_text:
            more_nested_key: 'value2'
        YAML

        config = described_class.load!(yaml)

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

      it 'loads the first document from a multi-doc YAML file' do
        yaml = <<~YAML
        spec:
          inputs:
            test_input:
        ---
        image: 'image:1.0'
        texts:
          nested_key: 'value1'
          more_text:
            more_nested_key: 'value2'
        YAML

        config = described_class.load!(yaml)

        expect(config).to eq({
          spec: {
            inputs: {
              test_input: nil
            }
          }
        })
      end
    end
  end

  describe '.load_result!' do
    context 'when syntax is invalid' do
      let(:yaml) { 'some: invalid: syntax' }

      it 'returns an invalid result object' do
        result = described_class.load_result!(yaml)

        expect(result).not_to be_valid
        expect(result.error).to be_a ::Gitlab::Config::Loader::FormatError
      end
    end

    context 'when syntax is valid and contains a header document' do
      let(:yaml) do
        <<~YAML
          a: 1
          ---
          b: 2
        YAML
      end

      let(:project) { create(:project) }

      it 'returns a result object' do
        result = described_class.load_result!(yaml, project: project)

        expect(result).to be_valid
        expect(result.error).to be_nil
        expect(result.header).to eq({ a: 1 })
        expect(result.content).to eq({ b: 2 })
      end
    end
  end
end
