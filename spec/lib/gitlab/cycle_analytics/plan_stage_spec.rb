require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::PlanStage do
  let(:stage_name) { :plan }

  it_behaves_like 'base stage'
end
