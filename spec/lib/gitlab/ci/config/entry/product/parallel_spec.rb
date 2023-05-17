# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe ::Gitlab::Ci::Config::Entry::Product::Parallel do
  let(:metadata) { {} }

  subject(:parallel) { described_class.new(config, **metadata) }

  shared_examples 'invalid config' do |error_message|
    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'returns error about invalid type' do
        expect(parallel.errors).to match(a_collection_including(error_message))
      end
    end
  end

  context 'with invalid config' do
    context 'when it is not a numeric value' do
      let(:config) { true }

      it_behaves_like 'invalid config', /should be an integer or a hash/
    end

    context 'when it is lower than one' do
      let(:config) { 0 }

      it_behaves_like 'invalid config', /must be greater than or equal to 1/
    end

    context 'when it is bigger than 200' do
      let(:config) { 201 }

      it_behaves_like 'invalid config', /must be less than or equal to 200/
    end

    context 'when it is not an integer' do
      let(:config) { 1.5 }

      it_behaves_like 'invalid config', /must be an integer/
    end

    context 'with empty hash config' do
      let(:config) { {} }

      it_behaves_like 'invalid config', /matrix builds config missing required keys: matrix/
    end
  end

  context 'with numeric config' do
    context 'when job is specified' do
      let(:config) { 2 }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(parallel.value).to match(number: config)
        end
      end

      context 'when :numeric is not allowed' do
        let(:metadata) { { allowed_strategies: [:matrix] } }

        it_behaves_like 'invalid config', /cannot use "parallel: <number>"/
      end
    end
  end

  context 'with matrix builds config' do
    context 'when matrix is specified' do
      let(:config) do
        {
          matrix: [
            { PROVIDER: 'aws', STACK: %w[monitoring app1 app2] },
            { PROVIDER: 'gcp', STACK: %w[data processing] }
          ]
        }
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(parallel.value).to match(matrix:
            [
              { PROVIDER: 'aws', STACK: %w[monitoring app1 app2] },
              { PROVIDER: 'gcp', STACK: %w[data processing] }
            ])
        end
      end

      context 'when :matrix is not allowed' do
        let(:metadata) { { allowed_strategies: [:numeric] } }

        it_behaves_like 'invalid config', /cannot use "parallel: matrix"/
      end
    end
  end
end
