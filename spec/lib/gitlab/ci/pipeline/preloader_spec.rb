# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Pipeline::Preloader do
  let(:stage) { double(:stage) }
  let(:commit) { double(:commit) }

  let(:pipeline) do
    double(:pipeline, commit: commit, stages: [stage])
  end

  describe '.preload!' do
    it 'preloads commit authors and number of warnings' do
      expect(commit).to receive(:lazy_author)
      expect(pipeline).to receive(:number_of_warnings)
      expect(stage).to receive(:number_of_warnings)

      described_class.preload!([pipeline])
    end

    it 'returns original collection' do
      allow(commit).to receive(:lazy_author)
      allow(pipeline).to receive(:number_of_warnings)
      allow(stage).to receive(:number_of_warnings)

      pipelines = [pipeline, pipeline]

      expect(described_class.preload!(pipelines)).to eq pipelines
    end
  end
end
