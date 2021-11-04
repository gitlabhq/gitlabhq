# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::IssueStageEvent do
  it { is_expected.to validate_presence_of(:stage_event_hash_id) }
  it { is_expected.to validate_presence_of(:issue_id) }
  it { is_expected.to validate_presence_of(:group_id) }
  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_presence_of(:start_event_timestamp) }

  it 'has state enum' do
    expect(described_class.states).to eq(Issue.available_states)
  end

  it_behaves_like 'StageEventModel' do
    let_it_be(:stage_event_factory) { :cycle_analytics_issue_stage_event }
    let_it_be(:issuable_factory) { :issue }
  end
end
