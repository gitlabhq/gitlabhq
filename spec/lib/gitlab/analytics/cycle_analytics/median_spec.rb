# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Median do
  let_it_be(:project) { create(:project, :repository) }

  let(:query) { Project.joins(merge_requests: :metrics) }

  let(:stage) do
    build(
      :cycle_analytics_project_stage,
      start_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestCreated.identifier,
      end_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged.identifier,
      project: project
    )
  end

  subject { described_class.new(stage: stage, query: query).seconds }

  around do |example|
    Timecop.freeze { example.run }
  end

  it 'retruns nil when no results' do
    expect(subject).to eq(nil)
  end

  it 'returns median duration seconds as float' do
    merge_request1 = create(:merge_request, source_branch: '1', target_project: project, source_project: project)
    merge_request2 = create(:merge_request, source_branch: '2', target_project: project, source_project: project)

    Timecop.travel(5.minutes.from_now) do
      merge_request1.metrics.update!(merged_at: Time.zone.now)
    end

    Timecop.travel(10.minutes.from_now) do
      merge_request2.metrics.update!(merged_at: Time.zone.now)
    end

    expect(subject).to be_within(0.5).of(7.5.minutes.seconds)
  end
end
