# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildStarted do
  it_behaves_like 'cycle analytics event'
end
