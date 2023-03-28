# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Loader::MultiDocYaml, feature_category: :pipeline_composition do
  let(:loader) { described_class.new(yml, max_documents: 2, reject_empty: reject_empty) }
  let(:reject_empty) { false }

  describe '#load!' do
    context 'when a simple single delimiter is being used' do
      let(:yml) do
        <<~YAML
        spec:
          inputs:
            env:
        ---
        test:
          script: echo "$[[ inputs.env ]]"
        YAML
      end

      it 'returns the loaded YAML with all keys as symbols' do
        expect(loader.load!).to contain_exactly(
          { spec: { inputs: { env: nil } } },
          { test: { script: 'echo "$[[ inputs.env ]]"' } }
        )
      end
    end

    context 'when the delimiter has a trailing configuration' do
      let(:yml) do
        <<~YAML
        spec:
          inputs:
            test_input:
        --- !test/content
        test_job:
          script: echo "$[[ inputs.test_input ]]"
        YAML
      end

      it 'returns the loaded YAML with all keys as symbols' do
        expect(loader.load!).to contain_exactly(
          { spec: { inputs: { test_input: nil } } },
          { test_job: { script: 'echo "$[[ inputs.test_input ]]"' } }
        )
      end
    end

    context 'when the YAML file has a leading delimiter' do
      let(:yml) do
        <<~YAML
        ---
        spec:
          inputs:
            test_input:
        --- !test/content
        test_job:
          script: echo "$[[ inputs.test_input ]]"
        YAML
      end

      it 'returns the loaded YAML with all keys as symbols' do
        expect(loader.load!).to contain_exactly(
          { spec: { inputs: { test_input: nil } } },
          { test_job: { script: 'echo "$[[ inputs.test_input ]]"' } }
        )
      end
    end

    context 'when the delimiter is followed by content on the same line' do
      let(:yml) do
        <<~YAML
        --- a: 1
        --- b: 2
        YAML
      end

      it 'loads the content as part of the document' do
        expect(loader.load!).to contain_exactly({ a: 1 }, { b: 2 })
      end
    end

    context 'when the delimiter does not have trailing whitespace' do
      let(:yml) do
        <<~YAML
        --- a: 1
        ---b: 2
        YAML
      end

      it 'is not a valid delimiter' do
        expect(loader.load!).to contain_exactly({ :'---b' => 2, a: 1 }) # rubocop:disable Style/HashSyntax
      end
    end

    context 'when the YAML file has whitespace preceding the content' do
      let(:yml) do
        <<-EOYML
          variables:
            SUPPORTED: "parsed"

          workflow:
            rules:
              - if: $VAR == "value"

          hello:
            script: echo world
        EOYML
      end

      it 'loads everything correctly' do
        expect(loader.load!).to contain_exactly(
          {
            variables: { SUPPORTED: 'parsed' },
            workflow: { rules: [{ if: '$VAR == "value"' }] },
            hello: { script: 'echo world' }
          }
        )
      end
    end

    context 'when the YAML file is empty' do
      let(:yml) { '' }

      it 'returns an empty array' do
        expect(loader.load!).to be_empty
      end
    end

    context 'when there are more than the maximum number of documents' do
      let(:yml) do
        <<~YAML
        --- a: 1
        --- b: 2
        --- c: 3
        --- d: 4
        YAML
      end

      it 'stops splitting documents after the maximum number' do
        expect(loader.load!).to contain_exactly({ a: 1 }, { b: 2 })
      end
    end

    context 'when the YAML contains empty documents' do
      let(:yml) do
        <<~YAML
        a: 1
        ---
        YAML
      end

      it 'raises an error' do
        expect { loader.load! }.to raise_error(::Gitlab::Config::Loader::Yaml::NotHashError)
      end

      context 'when reject_empty: true' do
        let(:reject_empty) { true }

        it 'loads only non empty documents' do
          expect(loader.load!).to contain_exactly({ a: 1 })
        end
      end
    end
  end

  describe '#load_raw!' do
    let(:yml) do
      <<~YAML
      spec:
        inputs:
          test_input:
      --- !test/content
      test_job:
        script: echo "$[[ inputs.test_input ]]"
      YAML
    end

    it 'returns the loaded YAML with all keys as strings' do
      expect(loader.load_raw!).to contain_exactly(
        { 'spec' => { 'inputs' => { 'test_input' => nil } } },
        { 'test_job' => { 'script' => 'echo "$[[ inputs.test_input ]]"' } }
      )
    end
  end

  describe '#valid?' do
    context 'when a document is invalid' do
      let(:yml) do
        <<~YAML
        a: b
        ---
        c
        YAML
      end

      it 'returns false' do
        expect(loader).not_to be_valid
      end
    end

    context 'when the number of documents is below the maximum and all documents are valid' do
      let(:yml) do
        <<~YAML
        a: b
        ---
        c: d
        YAML
      end

      it 'returns true' do
        expect(loader).to be_valid
      end
    end
  end
end
