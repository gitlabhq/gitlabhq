# frozen_string_literal: true

require 'spec_helper'
require_migration!('alter_vsa_issue_first_mentioned_in_commit_value')

RSpec.describe AlterVsaIssueFirstMentionedInCommitValue, schema: 20210114033715 do
  let(:group_stages) { table(:analytics_cycle_analytics_group_stages) }
  let(:value_streams) { table(:analytics_cycle_analytics_group_value_streams) }
  let(:namespaces) { table(:namespaces) }

  let(:namespace) { namespaces.create!(id: 1, name: 'group', path: 'group') }
  let(:value_stream) { value_streams.create!(name: 'test', group_id: namespace.id) }

  let!(:stage_1) { group_stages.create!(group_value_stream_id: value_stream.id, group_id: namespace.id, name: 'stage 1', start_event_identifier: described_class::ISSUE_FIRST_MENTIONED_IN_COMMIT_EE, end_event_identifier: 1) }
  let!(:stage_2) { group_stages.create!(group_value_stream_id: value_stream.id, group_id: namespace.id, name: 'stage 2', start_event_identifier: 2, end_event_identifier: described_class::ISSUE_FIRST_MENTIONED_IN_COMMIT_EE) }
  let!(:stage_3) { group_stages.create!(group_value_stream_id: value_stream.id, group_id: namespace.id, name: 'stage 3', start_event_identifier: described_class::ISSUE_FIRST_MENTIONED_IN_COMMIT_FOSS, end_event_identifier: 3) }

  describe '#up' do
    it 'changes the EE specific identifier values to the FOSS version' do
      migrate!

      expect(stage_1.reload.start_event_identifier).to eq(described_class::ISSUE_FIRST_MENTIONED_IN_COMMIT_FOSS)
      expect(stage_2.reload.end_event_identifier).to eq(described_class::ISSUE_FIRST_MENTIONED_IN_COMMIT_FOSS)
    end

    it 'does not change irrelevant records' do
      expect { migrate! }.not_to change { stage_3.reload }
    end
  end
end
