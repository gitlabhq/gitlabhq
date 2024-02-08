# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Interpolator, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }

  let(:result) { ::Gitlab::Ci::Config::Yaml::Result.new(config: [header, content]) }

  subject { described_class.new(result, arguments, []) }

  context 'when input data is valid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.website ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'correctly interpolates the config' do
      subject.interpolate!

      expect(subject).to be_interpolated
      expect(subject).to be_valid
      expect(subject.to_hash).to eq({ test: 'deploy gitlab.com' })
    end
  end

  context 'when config has a syntax error' do
    let(:result) { ::Gitlab::Ci::Config::Yaml::Result.new(error: 'Invalid configuration format') }

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'surfaces an error about invalid config' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq subject.errors.first
      expect(subject.errors).to include 'Invalid configuration format'
    end
  end

  context 'when spec header is missing but inputs are specified' do
    let(:header) { nil }
    let(:content) { { test: 'echo' } }
    let(:arguments) { { foo: 'bar' } }

    it 'surfaces an error about invalid inputs' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq subject.errors.first
      expect(subject.errors).to include('Given inputs not defined in the `spec` section of the included ' \
                                        'configuration file')
    end
  end

  context 'when spec header is invalid' do
    let(:header) do
      { spec: { arguments: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.website ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'surfaces an error about invalid header' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq subject.errors.first
      expect(subject.errors).to include('header:spec config contains unknown keys: arguments')
    end
  end

  context 'when provided interpolation argument is invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.website ]]' }
    end

    let(:arguments) do
      { website: ['gitlab.com'] }
    end

    it 'returns an error' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message).to eq subject.errors.first
      expect(subject.errors).to include '`website` input: provided value is not a string'
    end
  end

  context 'when interpolation block is invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.abc ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'returns an error' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.errors).to include 'unknown interpolation key: `abc`'
      expect(subject.error_message).to eq 'unknown interpolation key: `abc`'
    end
  end

  context 'when multiple interpolation blocks are invalid' do
    let(:header) do
      { spec: { inputs: { website: nil } } }
    end

    let(:content) do
      { test: 'deploy $[[ inputs.something.abc ]] $[[ inputs.cde ]] $[[ efg ]]' }
    end

    let(:arguments) do
      { website: 'gitlab.com' }
    end

    it 'returns an error' do
      subject.interpolate!

      expect(subject).not_to be_valid
      expect(subject.error_message)
        .to eq 'unknown interpolation key: `something`'
    end
  end

  describe '#to_hash' do
    context 'when interpolation is not used' do
      let(:result) do
        ::Gitlab::Ci::Config::Yaml::Result.new(config: content)
      end

      let(:content) do
        { test: 'deploy production' }
      end

      let(:arguments) { nil }

      it 'returns original content' do
        subject.interpolate!

        expect(subject.to_hash).to eq(content)
      end
    end

    context 'when interpolation is available' do
      let(:header) do
        { spec: { inputs: { website: nil } } }
      end

      let(:content) do
        { test: 'deploy $[[ inputs.website ]]' }
      end

      let(:arguments) do
        { website: 'gitlab.com' }
      end

      it 'correctly interpolates content' do
        subject.interpolate!

        expect(subject.to_hash).to eq({ test: 'deploy gitlab.com' })
      end
    end
  end
end
