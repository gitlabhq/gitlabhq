# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::IssueStageEvent do
  it { is_expected.to validate_presence_of(:stage_event_hash_id) }
  it { is_expected.to validate_presence_of(:issue_id) }
  it { is_expected.to validate_presence_of(:group_id) }
  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_presence_of(:start_event_timestamp) }

  it_behaves_like 'StageEventModel'
end
