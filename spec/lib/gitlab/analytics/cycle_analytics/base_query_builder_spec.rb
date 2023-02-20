# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder do
  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:mr1) { create(:merge_request, target_project: project, source_project: project, allow_broken: true, created_at: 3.months.ago) }
  let_it_be(:mr2) { create(:merge_request, target_project: project, source_project: project, allow_broken: true, created_at: 1.month.ago) }
  let_it_be(:user) { create(:user) }

  let(:params) { { current_user: user } }
  let(:records) do
    stage = build(:cycle_analytics_stage, {
      start_event_identifier: :merge_request_created,
      end_event_identifier: :merge_request_merged,
      namespace: project.reload.project_namespace
    })
    described_class.new(stage: stage, params: params).build.to_a
  end

  before do
    project.add_maintainer(user)
    mr1.metrics.update!(merged_at: 1.month.ago)
    mr2.metrics.update!(merged_at: Time.now)
    freeze_time
  end

  context 'when an unknown parent class is given' do
    it 'raises error' do
      stage = instance_double('Analytics::CycleAnalytics::Stage', parent: Issue.new)

      expect { described_class.new(stage: stage) }.to raise_error(/unknown parent_class: Issue/)
    end
  end

  describe 'date range parameters' do
    context 'when filters by only the `from` parameter' do
      before do
        params[:from] = 4.months.ago
      end

      it { expect(records.size).to eq(2) }
    end

    context 'when filters by both `from` and `to` parameters' do
      before do
        params.merge!(from: 4.months.ago, to: 2.months.ago)
      end

      it { expect(records.size).to eq(1) }
    end

    context 'invalid date range is provided' do
      before do
        params.merge!(from: 1.month.ago, to: 10.months.ago)
      end

      it { expect(records.size).to eq(0) }
    end
  end

  it 'scopes query within the target project' do
    other_mr = create(:merge_request, source_project: create(:project), allow_broken: true, created_at: 2.months.ago)
    other_mr.metrics.update!(merged_at: 1.month.ago)

    params[:from] = 1.year.ago

    expect(records.size).to eq(2)
  end

  describe 'in progress filter' do
    let_it_be(:mr3) { create(:merge_request, :opened, target_project: project, source_project: project, allow_broken: true, created_at: 3.months.ago) }
    let_it_be(:mr4) { create(:merge_request, :closed, target_project: project, source_project: project, allow_broken: true, created_at: 1.month.ago) }

    before do
      params[:from] = 5.months.ago
    end

    context 'when the filter is present' do
      before do
        params[:end_event_filter] = :in_progress
      end

      it 'returns only open items' do
        expect(records).to eq([mr3])
      end
    end

    context 'when the filter is absent' do
      it 'returns finished items' do
        expect(records).to match_array([mr1, mr2])
      end
    end
  end
end
