# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml, feature_category: :pipeline_authoring do
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
end
