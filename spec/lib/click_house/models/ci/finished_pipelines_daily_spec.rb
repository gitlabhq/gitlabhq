# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Models::Ci::FinishedPipelinesDaily, feature_category: :fleet_visibility do
  it_behaves_like 'a ci_finished_pipelines aggregation model', :ci_finished_pipelines_daily
end
