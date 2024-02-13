# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Loader::Yaml, feature_category: :pipeline_composition do
  let(:loader) { described_class.new(yml) }

  let(:yml) do
    <<~YAML
    image: 'image:1.0'
    texts:
      nested_key: 'value1'
      more_text:
        more_nested_key: 'value2'
    YAML
  end

  context 'when max yaml size and depth are set in ApplicationSetting' do
    let(:yaml_size) { 2.megabytes }
    let(:yaml_depth) { 200 }

    before do
      stub_application_setting(max_yaml_size_bytes: yaml_size, max_yaml_depth: yaml_depth)
    end

    it 'uses ApplicationSetting values rather than the defaults' do
      expect(Gitlab::Utils::DeepSize)
        .to receive(:new)
        .with(any_args, { max_size: yaml_size, max_depth: yaml_depth })
        .and_call_original

      loader.load!
    end
  end

  context 'when yaml syntax is correct' do
    let(:yml) { 'image: image:1.0' }

    describe '#valid?' do
      it 'returns true' do
        expect(loader).to be_valid
      end
    end

    describe '#load!' do
      it 'returns a valid hash' do
        expect(loader.load!).to eq(image: 'image:1.0')
      end
    end
  end

  context 'when yaml syntax is incorrect' do
    let(:yml) { '// incorrect' }

    describe '#valid?' do
      it 'returns false' do
        expect(loader).not_to be_valid
      end
    end

    describe '#load!' do
      it 'raises error' do
        expect { loader.load! }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          'Invalid configuration format'
        )
      end
    end
  end

  context 'when there is an unknown alias' do
    let(:yml) { 'steps: *bad_alias' }

    describe '#initialize' do
      it 'raises FormatError' do
        expect { loader }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          %r{unknown .+ bad_alias}i
        )
      end
    end
  end

  context 'when yaml config is empty' do
    let(:yml) { '' }

    describe '#valid?' do
      it 'returns false' do
        expect(loader).not_to be_valid
      end
    end

    describe '#load_raw!' do
      it 'raises error' do
        expect { loader.load_raw! }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          'Invalid configuration format'
        )
      end
    end
  end

  # Prevent Billion Laughs attack: https://gitlab.com/gitlab-org/gitlab-foss/issues/56018
  context 'when yaml size is too large' do
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
      YAML
    end

    describe '#valid?' do
      it 'returns false' do
        expect(loader).not_to be_valid
      end
    end

    describe '#load!' do
      it 'raises FormatError' do
        expect { loader.load! }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          'The parsed YAML is too big'
        )
      end
    end
  end

  # Prevent Billion Laughs attack: https://gitlab.com/gitlab-org/gitlab-foss/issues/56018
  context 'when yaml has cyclic data structure' do
    let(:yml) do
      <<~YAML
        --- &1
        - hi
        - *1
      YAML
    end

    describe '#valid?' do
      it 'returns false' do
        expect(loader.valid?).to be(false)
      end
    end

    describe '#load!' do
      it 'raises FormatError' do
        expect { loader.load! }.to raise_error(Gitlab::Config::Loader::FormatError, 'The parsed YAML is too big')
      end
    end
  end

  describe '#load_raw!' do
    it 'loads keys as strings' do
      expect(loader.load_raw!).to eq(
        'image' => 'image:1.0',
        'texts' => {
          'nested_key' => 'value1',
          'more_text' => {
            'more_nested_key' => 'value2'
          }
        }
      )
    end
  end

  describe '#load!' do
    it 'symbolizes keys' do
      expect(loader.load!).to eq(
        image: 'image:1.0',
        texts: {
          nested_key: 'value1',
          more_text: {
            more_nested_key: 'value2'
          }
        }
      )
    end
  end

  describe '#blank?' do
    context 'when the loaded YAML is empty' do
      let(:yml) do
        <<~YAML
        # only comments here
        YAML
      end

      it 'returns true' do
        expect(loader).to be_blank
      end
    end

    context 'when the loaded YAML has content' do
      let(:yml) do
        <<~YAML
        test: value
        YAML
      end

      it 'returns false' do
        expect(loader).not_to be_blank
      end
    end
  end

  describe '#raw' do
    it 'returns the unparsed YAML' do
      expect(loader.raw).to eq(yml)
    end
  end
end
