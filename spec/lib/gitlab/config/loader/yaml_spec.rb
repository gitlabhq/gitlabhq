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

  context 'when yaml uses a YAML tag that triggers an ArgumentError during deserialization' do
    around do |example|
      # ActiveSupport::OrderedHash registers a global YAML !!omap handler that is
      # incompatible with Psych 4+ (where Psych::Omap inherits from Hash, not Array).
      # We require it to reproduce the production behavior, then save and restore
      # YAML.domain_types to prevent this global state from leaking into other specs.
      require 'active_support/ordered_hash'
      saved_domain_types = YAML.domain_types.dup
      example.run
    ensure
      YAML.domain_types.replace(saved_domain_types)
    end

    let(:yml) do
      <<~YAML
        variables: !!omap
          - VARIABLE_NAME: 'variable_value'
      YAML
    end

    describe '#initialize' do
      it 'raises FormatError instead of unhandled ArgumentError' do
        expect { loader }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          'Invalid YAML syntax'
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

  context 'when raw yaml content is too large' do
    let(:yml) { 'a' * 3.megabytes }

    describe '#initialize' do
      it 'raises DataTooLargeError before parsing' do
        expect { loader }.to raise_error(
          Gitlab::Config::Loader::Yaml::DataTooLargeError,
          'The provided YAML is too big'
        )
      end
    end
  end

  context 'when raw yaml content is just under the size limit' do
    let(:yml) { "key: '#{'a' * (2.megabytes - 10)}'" }

    before do
      stub_application_setting(max_yaml_size_bytes: 2.megabytes)
    end

    describe '#initialize' do
      it 'does not raise an error before parsing' do
        expect { loader }.not_to raise_error
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

  describe 'filename parameter' do
    context 'when YAML has a parse error with filename' do
      let(:yml) { 'invalid: yaml: syntax' }
      let(:loader) { described_class.new(yml, filename: 'templates/bad.yml') }

      it 'raises FormatError with filename in message' do
        expect { loader.load! }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          '(templates/bad.yml): mapping values are not allowed in this context at line 1 column 14'
        )
      end
    end
  end

  describe 'Psych::SyntaxError normalization for HTML content' do
    let(:html_content) do
      <<~HTML
        <!-- BEGIN app/views/layouts/devise.html.haml -->
        <!DOCTYPE html>
        <html lang="en">
        <head><title>Sign in</title></head>
        <body>
        <form action="/users/sign_in" method="post">
        <label for="user_login">Username: or email</label>
        </form>
        </body>
        </html>
      HTML
    end

    context 'when content is HTML' do
      let(:yml) { html_content }

      it 'raises FormatError with a normalized message' do
        expect { loader }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          'Invalid configuration format'
        )
      end

      context 'when filename is provided' do
        let(:loader) { described_class.new(html_content, filename: 'templates/ci-template.yml') }

        it 'raises FormatError with filename in the normalized message' do
          expect { loader }.to raise_error(
            Gitlab::Config::Loader::FormatError,
            '(templates/ci-template.yml): Invalid configuration format'
          )
        end
      end
    end

    context 'when content is invalid YAML but not HTML' do
      let(:yml) { 'invalid: yaml: syntax' }

      it 'raises FormatError with the original Psych error message' do
        expect { loader }.to raise_error(
          Gitlab::Config::Loader::FormatError,
          /mapping values are not allowed in this context/
        )
      end
    end
  end
end
