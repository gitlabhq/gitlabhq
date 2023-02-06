# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CycleAnalytics::ProjectLevelStageAdapter, type: :model do
  let_it_be(:stage_name) { :review } # pre-defined, default stage
  let_it_be(:merge_request) do
    create(:merge_request, created_at: 5.hours.ago).tap do |mr|
      mr.metrics.update!(merged_at: mr.created_at + 1.hour)
    end
  end

  let_it_be(:project) { merge_request.target_project.reload }

  let(:stage) do
    params = Gitlab::Analytics::CycleAnalytics::DefaultStages
      .find_by_name!(stage_name)
      .merge(namespace: project.project_namespace)

    Analytics::CycleAnalytics::Stage.new(params)
  end

  around do |example|
    freeze_time { example.run }
  end

  subject { described_class.new(stage, from: 1.month.ago, to: Time.zone.now, current_user: merge_request.author) }

  it 'calculates median' do
    expect(subject.median).to be_within(1.hour).of(0.5)
  end

  it 'lists events' do
    expect(subject.events.size).to eq(1)
    expect(subject.events.first[:title]).to eq(merge_request.title)
  end

  it 'presents the data as json' do
    expect(subject.as_json).to include({ title: 'Review', value: 1.hour })
  end
end
