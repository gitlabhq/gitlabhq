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
    let_it_be(:project) { create(:project) }

    subject(:result) { described_class.load_result!(yaml, project: project) }

    context 'when syntax is invalid' do
      let(:yaml) { 'some: invalid: syntax' }

      it 'returns an invalid result object' do
        expect(result).not_to be_valid
        expect(result.error).to be_a ::Gitlab::Config::Loader::FormatError
      end
    end

    context 'when the first document is a header' do
      context 'with explicit document start marker' do
        let(:yaml) do
          <<~YAML
            ---
            spec:
            ---
            b: 2
          YAML
        end

        it 'considers the first document as header and the second as content' do
          expect(result).to be_valid
          expect(result.error).to be_nil
          expect(result.header).to eq({ spec: nil })
          expect(result.content).to eq({ b: 2 })
        end
      end
    end

    context 'when first document is empty' do
      let(:yaml) do
        <<~YAML
          ---
          ---
          b: 2
        YAML
      end

      it 'considers the first document as header and the second as content' do
        expect(result).not_to have_header
      end
    end

    context 'when first document is an empty hash' do
      let(:yaml) do
        <<~YAML
          {}
          ---
          b: 2
        YAML
      end

      it 'returns second document as a content' do
        expect(result).not_to have_header
        expect(result.content).to eq({ b: 2 })
      end
    end

    context 'when first an array' do
      let(:yaml) do
        <<~YAML
          ---
           - a
           - b
          ---
          b: 2
        YAML
      end

      it 'considers the first document as header and the second as content' do
        expect(result).not_to have_header
      end
    end

    context 'when the first document is not a header' do
      let(:yaml) do
        <<~YAML
          a: 1
          ---
          b: 2
        YAML
      end

      it 'considers the first document as content for backwards compatibility' do
        expect(result).to be_valid
        expect(result.error).to be_nil
        expect(result).not_to have_header
        expect(result.content).to eq({ a: 1 })
      end

      context 'with explicit document start marker' do
        let(:yaml) do
          <<~YAML
            ---
            a: 1
            ---
            b: 2
          YAML
        end

        it 'considers the first document as content for backwards compatibility' do
          expect(result).to be_valid
          expect(result.error).to be_nil
          expect(result).not_to have_header
          expect(result.content).to eq({ a: 1 })
        end
      end
    end

    context 'when the first document is not a header and second document is empty' do
      let(:yaml) do
        <<~YAML
          a: 1
          ---
        YAML
      end

      it 'considers the first document as content' do
        expect(result).to be_valid
        expect(result.error).to be_nil
        expect(result).not_to have_header
        expect(result.content).to eq({ a: 1 })
      end

      context 'with explicit document start marker' do
        let(:yaml) do
          <<~YAML
            ---
            a: 1
            ---
          YAML
        end

        it 'considers the first document as content' do
          expect(result).to be_valid
          expect(result.error).to be_nil
          expect(result).not_to have_header
          expect(result.content).to eq({ a: 1 })
        end
      end
    end
  end
end
