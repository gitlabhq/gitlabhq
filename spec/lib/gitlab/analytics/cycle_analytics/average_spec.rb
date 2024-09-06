# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Average, feature_category: :value_stream_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue_1) do
    # Duration: 10 days
    create(:issue, project: project, created_at: 20.days.ago).tap do |issue|
      issue.metrics.update!(first_mentioned_in_commit_at: 10.days.ago)
    end
  end

  let_it_be(:issue_2) do
    # Duration: 5 days
    create(:issue, project: project, created_at: 20.days.ago).tap do |issue|
      issue.metrics.update!(first_mentioned_in_commit_at: 15.days.ago)
    end
  end

  let(:stage) do
    build(
      :cycle_analytics_stage,
      start_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents::IssueCreated.identifier,
      end_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstMentionedInCommit.identifier,
      project: project
    )
  end

  let(:query) { Issue.joins(:metrics).in_projects(project.id) }

  before_all do
    freeze_time
  end

  after :all do
    unfreeze_time
  end

  subject(:average) { described_class.new(stage: stage, query: query) }

  describe '#seconds' do
    subject(:average_duration_in_seconds) { average.seconds }

    context 'when no results' do
      let(:query) { Issue.joins(:metrics).none }

      it { is_expected.to eq(nil) }
    end

    context 'returns the average duration in seconds' do
      it { is_expected.to be_within(3.seconds).of(7.5.days.to_f) }
    end
  end

  describe '#days' do
    subject(:average_duration_in_days) { average.days }

    context 'when no results' do
      let(:query) { Issue.joins(:metrics).none }

      it { is_expected.to eq(nil) }
    end

    context 'returns the average duration in days' do
      it { is_expected.to be_within(3.seconds).of(7.5) }
    end
  end
end
