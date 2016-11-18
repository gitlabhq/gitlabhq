require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::IssueStage do
  let(:stage_name) { :issue }

  it_behaves_like 'base stage'
end
