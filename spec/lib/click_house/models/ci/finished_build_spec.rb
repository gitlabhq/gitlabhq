# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Models::Ci::FinishedBuild, feature_category: :fleet_visibility do
  describe '.table_name' do
    it 'returns the correct table name' do
      expect(described_class.table_name).to eq('ci_finished_builds')
    end
  end
end
