# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrendingProjectsWorker, feature_category: :source_code_management do
  describe '#perform' do
    it 'does nothing' do
      expect(described_class.new.perform).to be_nil
    end
  end
end
