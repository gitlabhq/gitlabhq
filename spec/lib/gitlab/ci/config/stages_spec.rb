# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Stages, feature_category: :pipeline_composition do
  describe '.wrap_with_edge_stages' do
    subject { described_class.wrap_with_edge_stages(stages) }

    context 'with nil value' do
      let(:stages) { nil }

      it { is_expected.to eq %w[.pre .post] }
    end

    context 'with values' do
      let(:stages) { %w[s1 .pre] }

      it { is_expected.to eq %w[.pre s1 .post] }
    end
  end

  describe '#inject_edge_stages!' do
    subject { described_class.new(config).inject_edge_stages! }

    context 'without stages' do
      let(:config) do
        {
          test: { script: 'test' }
        }
      end

      it { is_expected.to match config }
    end

    context 'with values' do
      let(:config) do
        {
          stages: %w[stage1 stage2],
          test: { script: 'test' }
        }
      end

      let(:expected_stages) do
        %w[.pre stage1 stage2 .post]
      end

      it { is_expected.to match(config.merge(stages: expected_stages)) }
    end

    context 'with bad values' do
      let(:config) do
        {
          stages: 'stage1',
          test: { script: 'test' }
        }
      end

      it { is_expected.to match(config) }
    end

    context 'with collision values' do
      let(:config) do
        {
          stages: %w[.post stage1 .pre .post stage2],
          test: { script: 'test' }
        }
      end

      let(:expected_stages) do
        %w[.pre stage1 stage2 .post]
      end

      it { is_expected.to match(config.merge(stages: expected_stages)) }
    end
  end
end
