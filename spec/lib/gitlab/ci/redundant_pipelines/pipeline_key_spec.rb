# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RedundantPipelines::PipelineKey, feature_category: :continuous_integration do
  let(:key) { described_class.new(42, 100) }

  describe '.of' do
    it 'takes the composite key of a pipeline' do
      pipeline = build_stubbed(:ci_pipeline, id: 42, partition_id: 100)

      expect(described_class.of(pipeline)).to eq(key)
    end
  end

  describe '.parse' do
    it 'reads back a key it wrote' do
      expect(described_class.parse(key.to_s)).to eq(key)
    end
  end

  describe '#to_s' do
    it 'joins the pipeline and partition ids' do
      expect(key.to_s).to eq('42:100')
    end
  end

  describe '#==' do
    it 'is equal to another key for the same pipeline' do
      expect(key).to eq(described_class.new(42, 100))
    end

    it 'is not equal to a key for another pipeline' do
      expect(key).not_to eq(described_class.new(43, 100))
    end

    it 'is not equal to a key for another partition' do
      expect(key).not_to eq(described_class.new(42, 101))
    end
  end

  describe '#hash' do
    it 'lets keys for the same pipeline collapse in a set' do
      expect([key, described_class.new(42, 100)].uniq.size).to eq(1)
    end
  end
end
