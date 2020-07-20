# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrendingProjectsWorker do
  describe '#perform' do
    it 'refreshes the trending projects' do
      expect(TrendingProject).to receive(:refresh!)

      described_class.new.perform
    end
  end
end
