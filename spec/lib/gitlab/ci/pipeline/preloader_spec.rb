# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Preloader do
  describe '.preload' do
    it 'preloads the author of every pipeline commit' do
      commit = double(:commit)
      pipeline = double(:pipeline, commit: commit)

      expect(commit)
        .to receive(:lazy_author)

      expect(pipeline)
        .to receive(:number_of_warnings)

      described_class.preload([pipeline])
    end
  end
end
