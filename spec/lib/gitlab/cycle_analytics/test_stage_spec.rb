require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::TestStage do
  let(:stage_name) { :test }

  it_behaves_like 'base stage'
end
