# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml::Loader, feature_category: :pipeline_composition do
  describe '#to_result' do
    let_it_be(:project) { create(:project) }

    subject(:result) { described_class.new(yaml, project: project).to_result }

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
