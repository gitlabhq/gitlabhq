# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Models::Ci::FinishedPipeline, feature_category: :fleet_visibility do
  it { is_expected.to be_a(ClickHouse::Models::BaseModel) }

  describe '.table_name' do
    it { expect(described_class.table_name).to eq('ci_finished_pipelines') }
  end

  it_behaves_like 'a ci_finished_pipelines aggregation model', :ci_finished_pipelines
end
