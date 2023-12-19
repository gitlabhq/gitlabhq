# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::TextInterpolator, feature_category: :pipeline_composition do
  let(:result) { ::Gitlab::Ci::Config::Yaml::Result.new(config: [header, content]) }

  subject(:interpolator) { described_class.new(result, arguments, []) }

  context 'when input data is valid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      "test: 'deploy $[[ inputs.website ]]'"
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'correctly interpolates the config' do
      interpolator.interpolate!

      expect(interpolator).to be_interpolated
      expect(interpolator).to be_valid
      expect(interpolator.to_result).to eq("test: 'deploy gitlab.com'")
    end
  end

  context 'when config has a syntax error' do
    let(:result) { ::Gitlab::Ci::Config::Yaml::Result.new(error: 'Invalid configuration format') }

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'surfaces an error about invalid config' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('Invalid configuration format')
    end
  end

  context 'when spec header is missing but inputs are specified' do
    let(:header) { nil }
    let(:content) { "test: 'echo'" }
    let(:arguments) { { foo: 'bar' } }

    it 'surfaces an error about invalid inputs' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq(
        'Given inputs not defined in the `spec` section of the included configuration file'
      )
    end
  end

  context 'when spec header is invalid' do
    let(:header) do
      { spec: { arguments: { website: nil } } }
    end

    let(:content) do
      "test: 'deploy $[[ inputs.website ]]'"
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'surfaces an error about invalid header' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('header:spec config contains unknown keys: arguments')
    end
  end

  context 'when provided interpolation argument is invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      "test: 'deploy $[[ inputs.website ]]'"
    end

    let(:arguments) do
      { website: ['gitlab.com'] }
    end

    it 'returns an error about the invalid argument' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('`website` input: provided value is not a string')
    end
  end

  context 'when interpolation block is invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      "test: 'deploy $[[ inputs.abc ]]'"
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'returns an error about the invalid block' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('unknown interpolation key: `abc`')
    end
  end

  context 'when multiple interpolation blocks are invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      "test: 'deploy $[[ inputs.something.abc ]] $[[ inputs.cde ]] $[[ efg ]]'"
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'stops execution after the first invalid block' do
      interpolator.interpolate!

      expect(interpolator).not_to be_valid
      expect(interpolator.error_message).to eq('unknown interpolation key: `something`')
    end
  end

  context 'when there are many invalid arguments' do
    let(:header) do
      { spec: { inputs: {
        allow_failure: { type: 'boolean' },
        image: nil,
        parallel: { type: 'number' },
        website: nil
      } } }
    end

    let(:content) do
      "test: 'deploy $[[ inputs.website ]] $[[ inputs.parallel ]] $[[ inputs.allow_failure ]] $[[ inputs.image ]]'"
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

  describe '#to_result' do
    context 'when interpolation is not used' do
      let(:result) do
        ::Gitlab::Ci::Config::Yaml::Result.new(config: content)
      end

      let(:content) do
        "test: 'deploy production'"
      end

      let(:arguments) { nil }

      it 'returns original content' do
        interpolator.interpolate!

        expect(interpolator.to_result).to eq(content)
      end
    end

    context 'when interpolation is available' do
      let(:header) do
        { spec: { inputs: { website: nil } } }
      end

      let(:content) do
        "test: 'deploy $[[ inputs.website ]]'"
      end

      let(:arguments) do
        { website: 'gitlab.com' }
      end

      it 'correctly interpolates content' do
        interpolator.interpolate!

        expect(interpolator.to_result).to eq("test: 'deploy gitlab.com'")
      end
    end
  end
end
