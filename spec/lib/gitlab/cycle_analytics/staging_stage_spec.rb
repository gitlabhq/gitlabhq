require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::StagingStage do
  let(:stage_name) { :staging }

  it_behaves_like 'base stage'
end
