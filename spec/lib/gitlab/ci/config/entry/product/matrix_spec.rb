# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe ::Gitlab::Ci::Config::Entry::Product::Matrix do
  subject(:matrix) { described_class.new(config) }

  describe 'validations' do
    before do
      matrix.compose!
    end

    context 'when entry config value is correct' do
      let(:config) do
        [
          { 'VAR_1' => [1, 2, 3], 'VAR_2' => [4, 5, 6] },
          { 'VAR_3' => %w[a b], 'VAR_4' => %w[c d] }
        ]
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end
    end

    context 'when entry config generates too many jobs' do
      let(:config) do
        [
          {
            'VAR_1' => (1..10).to_a,
            'VAR_2' => (11..31).to_a
          }
        ]
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about too many jobs' do
          expect(matrix.errors)
            .to include('matrix config generates too many jobs (maximum is 200)')
        end
      end
    end

    context 'when entry config has only one variable with multiple values' do
      let(:config) do
        [
          {
            'VAR_1' => %w[build test]
          }
        ]
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#errors' do
        it 'returns no errors' do
          expect(matrix.errors)
            .to be_empty
        end
      end

      describe '#value' do
        before do
          matrix.compose!
        end

        it 'returns the value without raising an error' do
          expect(matrix.value).to eq([{ 'VAR_1' => %w[build test] }])
        end
      end

      context 'when entry config has only one variable with one value' do
        let(:config) do
          [
            {
              'VAR_1' => %w[test]
            }
          ]
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#errors' do
          it 'returns no errors' do
            expect(matrix.errors)
              .to be_empty
          end
        end

        describe '#value' do
          before do
            matrix.compose!
          end

          it 'returns the value without raising an error' do
            expect(matrix.value).to eq([{ 'VAR_1' => %w[test] }])
          end
        end
      end
    end

    context 'when config value has wrong type' do
      let(:config) { {} }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          expect(matrix.errors)
            .to include('matrix config should be an array of hashes')
        end
      end
    end
  end

  describe '.compose!' do
    context 'when valid job entries composed' do
      let(:config) do
        [
          { PROVIDER: 'aws', STACK: %w[monitoring app1 app2] },
          { STACK: %w[monitoring backup app], PROVIDER: 'ovh' },
          { PROVIDER: 'gcp', STACK: %w[data processing], ARGS: 'normal' },
          { PROVIDER: 'vultr', STACK: 'data', ARGS: 'store' }
        ]
      end

      before do
        matrix.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(matrix.value).to match(
            [
              { 'PROVIDER' => %w[aws], 'STACK' => %w[monitoring app1 app2] },
              { 'PROVIDER' => %w[ovh], 'STACK' => %w[monitoring backup app] },
              { 'ARGS' => %w[normal], 'PROVIDER' => %w[gcp], 'STACK' => %w[data processing] },
              { 'ARGS' => %w[store], 'PROVIDER' => %w[vultr], 'STACK' => %w[data] }
            ]
          )
        end
      end

      describe '#descendants' do
        it 'creates valid descendant nodes' do
          expect(matrix.descendants.count).to eq(config.size)
          expect(matrix.descendants)
            .to all(be_an_instance_of(::Gitlab::Ci::Config::Entry::Product::Variables))
        end
      end
    end

    context 'with empty config' do
      let(:config) { [] }

      before do
        matrix.compose!
      end

      describe '#value' do
        it 'returns empty value' do
          expect(matrix.value).to eq([])
        end
      end
    end
  end

  describe '#number_of_generated_jobs' do
    before do
      matrix.compose!
    end

    subject { matrix.number_of_generated_jobs }

    context 'with empty config' do
      let(:config) { [] }

      it { is_expected.to be_zero }
    end

    context 'with only one variable' do
      let(:config) do
        [{ 'VAR_1' => (1..10).to_a }]
      end

      it { is_expected.to eq(10) }
    end

    context 'with two variables' do
      let(:config) do
        [{ 'VAR_1' => (1..10).to_a, 'VAR_2' => (1..5).to_a }]
      end

      it { is_expected.to eq(50) }
    end

    context 'with two sets of variables' do
      let(:config) do
        [
          { 'VAR_1' => (1..10).to_a, 'VAR_2' => (1..5).to_a },
          { 'VAR_3' => (1..2).to_a, 'VAR_4' => (1..3).to_a }
        ]
      end

      it { is_expected.to eq(56) }
    end
  end
end
