# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::TextInterpolator, feature_category: :pipeline_composition, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/440667' do
  let(:arguments) { { website: 'gitlab.com' } }
  let(:content) { ::Gitlab::Config::Loader::Yaml.new("test: 'deploy $[[ inputs.website ]]'") }
  let(:header) { ::Gitlab::Config::Loader::Yaml.new("spec:\n  inputs:\n     website: ") }
  let(:documents) { ::Gitlab::Ci::Config::Yaml::Documents.new([header, content]) }

  subject(:interpolator) { described_class.new(documents, arguments, []) }

  context 'when input data is valid' do
    it 'correctly interpolates the config' do
      interpolator.interpolate!

      expect(interpolator).to be_interpolated
      expect(interpolator).to be_valid
      expect(interpolator.to_result).to eq("test: 'deploy gitlab.com'")
    end
  end

  context 'when interpolation is not used' do
    let(:arguments) { nil }
    let(:content) { ::Gitlab::Config::Loader::Yaml.new("test: 'deploy production'") }
    let(:documents) { ::Gitlab::Ci::Config::Yaml::Documents.new([content]) }

    it 'returns original content' do
      interpolator.interpolate!

      expect(interpolator).not_to be_interpolated
      expect(interpolator).to be_valid
      expect(interpolator.to_result).to eq("test: 'deploy production'")
    end
  end

  context 'when spec header is missing but inputs are specified' do
    let(:documents) { ::Gitlab::Ci::Config::Yaml::Documents.new([content]) }

    it 'surfaces an error about invalid inputs' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq(
        'Given inputs not defined in the `spec` section of the included configuration file'
      )
    end
  end

  context 'when spec header is invalid' do
    let(:header) { ::Gitlab::Config::Loader::Yaml.new("spec:\n  arguments:\n     website:") }

    it 'surfaces an error about invalid header' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('header:spec config contains unknown keys: arguments')
    end
  end

  context 'when provided interpolation argument is invalid' do
    let(:arguments) { { website: ['gitlab.com'] } }

    it 'returns an error about the invalid argument' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('`website` input: provided value is not a string')
    end
  end

  context 'when interpolation block is invalid' do
    let(:content) { ::Gitlab::Config::Loader::Yaml.new("test: 'deploy $[[ inputs.abc ]]'") }

    it 'returns an error about the invalid block' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('unknown interpolation key: `abc`')
    end
  end

  context 'when multiple interpolation blocks are invalid' do
    let(:content) do
      ::Gitlab::Config::Loader::Yaml.new("test: 'deploy $[[ inputs.something.abc ]] $[[ inputs.cde ]] $[[ efg ]]'")
    end

    it 'stops execution after the first invalid block' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('unknown interpolation key: `something`')
    end
  end

  context 'when there are many invalid arguments' do
    let(:header) do
      ::Gitlab::Config::Loader::Yaml.new(
        <<~YAML
        spec:
          inputs:
            allow_failure:
              type: boolean
            image:
            parallel:
              type: number
            website:
        YAML
      )
    end

    let(:content) do
      ::Gitlab::Config::Loader::Yaml.new(
        "test: 'deploy $[[ inputs.website ]] $[[ inputs.parallel ]] $[[ inputs.allow_failure ]] $[[ inputs.image ]]'"
      )
    end

    let(:arguments) do
      { allow_failure: 'no', parallel: 'yes', website: 8 }
    end

    it 'reports a maximum of 3 errors in the error message' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq(
        '`allow_failure` input: provided value is not a boolean, ' \
        '`image` input: required value has not been provided, ' \
        '`parallel` input: provided value is not a number'
      )
      expect(interpolator.errors).to contain_exactly(
        '`allow_failure` input: provided value is not a boolean',
        '`image` input: required value has not been provided',
        '`parallel` input: provided value is not a number',
        '`website` input: provided value is not a string'
      )
    end
  end
end
