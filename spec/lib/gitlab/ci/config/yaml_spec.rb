# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml, feature_category: :pipeline_composition do
  let(:yaml) do
    <<~YAML
    image: 'image:1.0'
    texts:
      nested_key: 'value1'
      more_text:
        more_nested_key: 'value2'
    YAML
  end

  describe '.load!' do
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
end
