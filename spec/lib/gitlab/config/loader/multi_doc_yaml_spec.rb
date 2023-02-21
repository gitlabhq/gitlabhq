# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Loader::MultiDocYaml, feature_category: :pipeline_composition do
  let(:loader) { described_class.new(yml, max_documents: 2) }

  describe '#load!' do
    let(:yml) do
      <<~YAML
      spec:
        inputs:
          test_input:
      ---
      test_job:
        script: echo "$[[ inputs.test_input ]]"
      YAML
    end

    it 'returns the loaded YAML with all keys as symbols' do
      expect(loader.load!).to eq([
        { spec: { inputs: { test_input: nil } } },
        { test_job: { script: 'echo "$[[ inputs.test_input ]]"' } }
      ])
    end

    context 'when the YAML file is empty' do
      let(:yml) { '' }

      it 'returns an empty array' do
        expect(loader.load!).to be_empty
      end
    end

    context 'when the parsed YAML is too big' do
      let(:yml) do
        <<~YAML
        a: &a ["lol","lol","lol","lol","lol","lol","lol","lol","lol"]
        b: &b [*a,*a,*a,*a,*a,*a,*a,*a,*a]
        c: &c [*b,*b,*b,*b,*b,*b,*b,*b,*b]
        d: &d [*c,*c,*c,*c,*c,*c,*c,*c,*c]
        e: &e [*d,*d,*d,*d,*d,*d,*d,*d,*d]
        f: &f [*e,*e,*e,*e,*e,*e,*e,*e,*e]
        g: &g [*f,*f,*f,*f,*f,*f,*f,*f,*f]
        h: &h [*g,*g,*g,*g,*g,*g,*g,*g,*g]
        i: &i [*h,*h,*h,*h,*h,*h,*h,*h,*h]
        ---
        a: &a ["lol","lol","lol","lol","lol","lol","lol","lol","lol"]
        b: &b [*a,*a,*a,*a,*a,*a,*a,*a,*a]
        c: &c [*b,*b,*b,*b,*b,*b,*b,*b,*b]
        d: &d [*c,*c,*c,*c,*c,*c,*c,*c,*c]
        e: &e [*d,*d,*d,*d,*d,*d,*d,*d,*d]
        f: &f [*e,*e,*e,*e,*e,*e,*e,*e,*e]
        g: &g [*f,*f,*f,*f,*f,*f,*f,*f,*f]
        h: &h [*g,*g,*g,*g,*g,*g,*g,*g,*g]
        i: &i [*h,*h,*h,*h,*h,*h,*h,*h,*h]
        YAML
      end

      it 'raises a DataTooLargeError' do
        expect { loader.load! }.to raise_error(described_class::DataTooLargeError, 'The parsed YAML is too big')
      end
    end

    context 'when a document is not a hash' do
      let(:yml) do
        <<~YAML
        not_a_hash
        ---
        test_job:
          script: echo "$[[ inputs.test_input ]]"
        YAML
      end

      it 'raises a NotHashError' do
        expect { loader.load! }.to raise_error(described_class::NotHashError, 'Invalid configuration format')
      end
    end

    context 'when there are too many documents' do
      let(:yml) do
        <<~YAML
        a: b
        ---
        c: d
        ---
        e: f
        YAML
      end

      it 'raises a TooManyDocumentsError' do
        expect { loader.load! }.to raise_error(
          described_class::TooManyDocumentsError,
          'The parsed YAML has too many documents'
        )
      end
    end
  end
end
