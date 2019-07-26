# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Config::Loader::Yaml do
  let(:loader) { described_class.new(yml) }

  context 'when yaml syntax is correct' do
    let(:yml) { 'image: ruby:2.2' }

    describe '#valid?' do
      it 'returns true' do
        expect(loader).to be_valid
      end
    end

    describe '#load!' do
      it 'returns a valid hash' do
        expect(loader.load!).to eq(image: 'ruby:2.2')
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
          'Unknown alias: bad_alias'
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
  end

  # Prevent Billion Laughs attack: https://gitlab.com/gitlab-org/gitlab-ce/issues/56018
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

      it 'returns true if "ci_yaml_limit_size" feature flag is disabled' do
        stub_feature_flags(ci_yaml_limit_size: false)

        expect(loader).to be_valid
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

  # Prevent Billion Laughs attack: https://gitlab.com/gitlab-org/gitlab-ce/issues/56018
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
end
