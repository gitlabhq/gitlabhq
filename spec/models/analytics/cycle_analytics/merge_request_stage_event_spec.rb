# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::MergeRequestStageEvent do
  it { is_expected.to validate_presence_of(:stage_event_hash_id) }
  it { is_expected.to validate_presence_of(:merge_request_id) }
  it { is_expected.to validate_presence_of(:group_id) }
  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_presence_of(:start_event_timestamp) }

  it 'has state enum' do
    expect(described_class.states).to eq(MergeRequest.available_states)
  end

  it_behaves_like 'StageEventModel'
end
