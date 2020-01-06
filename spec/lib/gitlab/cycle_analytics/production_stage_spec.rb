# frozen_string_literal: true

require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::ProductionStage do
  let(:stage_name) { 'Total' }

  it_behaves_like 'base stage'
end
