# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CycleAnalytics::ProductionStage do
  let(:stage_name) { 'Total' }

  it_behaves_like 'base stage'
end
