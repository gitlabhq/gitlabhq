# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Input::Inputs, feature_category: :pipeline_composition do
  describe '#valid?' do
    let(:spec) { { website: nil } }

    it 'describes user-provided inputs' do
      inputs = described_class.new(spec, { website: 'http://example.gitlab.com' })

      expect(inputs).to be_valid
    end
  end

  context 'when proper specification has been provided' do
    let(:spec) do
      {
        website: nil,
        env: { default: 'development' },
        run: { options: %w[tests spec e2e] }
      }
    end

    let(:args) { { website: 'https://gitlab.com', run: 'tests' } }

    it 'fabricates desired input arguments' do
      inputs = described_class.new(spec, args)

      expect(inputs).to be_valid
      expect(inputs.count).to eq 3
      expect(inputs.to_hash).to eq(args.merge(env: 'development'))
    end
  end

  context 'when inputs and args are empty' do
    it 'is a valid use-case' do
      inputs = described_class.new({}, {})

      expect(inputs).to be_valid
      expect(inputs.to_hash).to be_empty
    end
  end

  context 'when there are arguments recoincilation errors present' do
    context 'when required argument is missing' do
      let(:spec) { { website: nil } }

      it 'returns an error' do
        inputs = described_class.new(spec, {})

        expect(inputs).not_to be_valid
        expect(inputs.errors.first).to eq '`website` input: required value has not been provided'
      end
    end

    context 'when argument is not present but configured as allowlist' do
      let(:spec) do
        { run: { options: %w[opt1 opt2] } }
      end

      it 'returns an error' do
        inputs = described_class.new(spec, {})

        expect(inputs).not_to be_valid
        expect(inputs.errors.first).to eq '`run` input: argument not provided'
      end
    end
  end

  context 'when unknown specification argument has been used' do
    let(:spec) do
      {
        website: nil,
        env: { default: 'development' },
        run: { options: %w[tests spec e2e] },
        test: { unknown: 'something' }
      }
    end

    let(:args) { { website: 'https://gitlab.com', run: 'tests' } }

    it 'fabricates an unknown argument entry and returns an error' do
      inputs = described_class.new(spec, args)

      expect(inputs).not_to be_valid
      expect(inputs.count).to eq 4
      expect(inputs.errors.first).to eq '`test` input: unrecognized input argument specification: `unknown`'
    end
  end

  context 'when unknown arguments are being passed by a user' do
    let(:spec) do
      { env: { default: 'development' } }
    end

    let(:args) { { website: 'https://gitlab.com', run: 'tests' } }

    it 'returns an error with a list of unknown arguments' do
      inputs = described_class.new(spec, args)

      expect(inputs).not_to be_valid
      expect(inputs.errors.first).to eq 'unknown input arguments: [:website, :run]'
    end
  end

  context 'when composite specification is being used' do
    let(:spec) do
      {
        env: {
          default: 'dev',
          options: %w[test dev prod]
        }
      }
    end

    let(:args) { { env: 'dev' } }

    it 'returns an error describing an unknown specification' do
      inputs = described_class.new(spec, args)

      expect(inputs).not_to be_valid
      expect(inputs.errors.first).to eq '`env` input: unrecognized input argument definition'
    end
  end
end
