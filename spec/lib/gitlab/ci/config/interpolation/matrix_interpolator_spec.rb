# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::MatrixInterpolator, feature_category: :pipeline_composition do
  let(:matrix_variables) { { 'OS' => 'linux', 'ARCH' => 'amd64', 'VERSION' => '1.0' } }

  subject(:interpolator) { described_class.new(matrix_variables) }

  describe '#interpolate' do
    context 'when value is a string' do
      it 'interpolates matrix expressions' do
        result = interpolator.interpolate('$[[ matrix.OS ]]')

        expect(result).to eq('linux')
      end

      it 'interpolates multiple matrix expressions' do
        result = interpolator.interpolate('$[[ matrix.OS ]]-$[[ matrix.ARCH ]]')

        expect(result).to eq('linux-amd64')
      end

      it 'handles whitespace in expressions' do
        result = interpolator.interpolate('$[[matrix.OS]]')
        expect(result).to eq('linux')

        result = interpolator.interpolate('$[[ matrix.ARCH ]]')
        expect(result).to eq('amd64')
      end

      it 'leaves non-matrix expressions unchanged' do
        result = interpolator.interpolate('$CI_JOB_NAME')

        expect(result).to eq('$CI_JOB_NAME')
      end

      it 'collects errors for missing matrix variables' do
        result = interpolator.interpolate('$[[ matrix.MISSING ]]')

        expect(result).to eq('$[[ matrix.MISSING ]]')
        expect(interpolator.errors).to contain_exactly("'MISSING' does not exist in matrix configuration")
      end

      it 'handles mixed content' do
        result = interpolator.interpolate('build-$[[ matrix.OS ]]-$CI_JOB_ID')

        expect(result).to eq('build-linux-$CI_JOB_ID')
      end

      it 'recognizes all possible symbols used in matrix variable names' do
        matrix_variables = { 'VAR_01-666' => 'valid' }
        interpolator = described_class.new(matrix_variables)

        result = interpolator.interpolate('$[[ matrix.VAR_01-666 ]]')

        expect(result).to eq('valid')
      end
    end

    context 'when value is a hash' do
      it 'recursively interpolates hash values' do
        config = {
          job: 'build-$[[ matrix.OS ]]',
          parallel: {
            matrix: [{ 'TARGET' => '$[[ matrix.ARCH ]]' }]
          }
        }

        result = interpolator.interpolate(config)

        expect(result).to eq({
          job: 'build-linux',
          parallel: {
            matrix: [{ 'TARGET' => 'amd64' }]
          }
        })
      end

      it 'handles nested hashes' do
        config = {
          needs: {
            job: 'test-$[[ matrix.VERSION ]]',
            artifacts: true
          }
        }

        result = interpolator.interpolate(config)

        expect(result[:needs][:job]).to eq('test-1.0')
        expect(result[:needs][:artifacts]).to be true
      end
    end

    context 'when value is an array' do
      it 'recursively interpolates array elements' do
        config = [
          'job-$[[ matrix.OS ]]',
          { job: 'build-$[[ matrix.ARCH ]]' }
        ]

        result = interpolator.interpolate(config)

        expect(result).to eq([
          'job-linux',
          { job: 'build-amd64' }
        ])
      end
    end

    context 'when value is neither string, hash, nor array' do
      it 'returns the value unchanged' do
        expect(interpolator.interpolate(42)).to eq(42)
        expect(interpolator.interpolate(true)).to be true
        expect(interpolator.interpolate(nil)).to be_nil
      end
    end
  end

  context 'with empty matrix variables' do
    let(:matrix_variables) { {} }

    it 'collects errors for matrix expressions' do
      result = interpolator.interpolate('$[[ matrix.OS ]]')

      expect(result).to eq('$[[ matrix.OS ]]')
      expect(interpolator.errors).to contain_exactly("'OS' does not exist in matrix configuration")
    end
  end

  context 'with nil matrix variables' do
    let(:matrix_variables) { nil }

    it 'initializes with empty hash and collects errors for matrix expressions' do
      result = interpolator.interpolate('$[[ matrix.OS ]]')

      expect(result).to eq('$[[ matrix.OS ]]')
      expect(interpolator.errors).to contain_exactly("'OS' does not exist in matrix configuration")
    end
  end
end
