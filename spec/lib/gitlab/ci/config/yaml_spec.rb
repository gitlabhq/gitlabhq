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

    context 'when given a user' do
      let(:user) { instance_double(User) }

      subject(:config) { described_class.load!(yaml, current_user: user) }

      it 'passes it to Loader' do
        expect(::Gitlab::Ci::Config::Yaml::Loader).to receive(:new).with(yaml, current_user: user).and_call_original

        config
      end
    end
  end
end
