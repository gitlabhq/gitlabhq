# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::RecordsFetcher do
  before_all do
    freeze_time
  end

  let(:params) { { from: 1.year.ago, current_user: user } }
  let(:records_fetcher) do
    Gitlab::Analytics::CycleAnalytics::DataCollector.new(
      stage: stage,
      params: params
    ).records_fetcher
  end

  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:user) { create(:user) }

  subject do
    records_fetcher.serialized_records
  end

  describe '#serialized_records' do
    shared_context 'when records are loaded by maintainer' do
      before do
        project.add_member(user, Gitlab::Access::DEVELOPER)
      end

      it 'returns all records' do
        expect(subject.size).to eq(2)
      end

      it 'passes a hash with all expected attributes to the serializer' do
        expected_attributes = [
          'created_at',
          'id',
          'iid',
          'title',
          'end_event_timestamp',
          'start_event_timestamp',
          'total_time',
          :author,
          :namespace_path,
          :project_path
        ]
        serializer = instance_double(records_fetcher.send(:serializer).class.name)
        allow(records_fetcher).to receive(:serializer).and_return(serializer)
        expect(serializer).to receive(:represent).twice.with(hash_including(*expected_attributes)).and_return({})

        subject
      end
    end

    describe 'for issue based stage' do
      let_it_be(:issue1) { create(:issue, project: project) }
      let_it_be(:issue2) { create(:issue, project: project, confidential: true) }

      let(:stage) do
        build(:cycle_analytics_stage, {
          start_event_identifier: :plan_stage_start,
          end_event_identifier: :issue_first_mentioned_in_commit,
          project: project
        })
      end

      before do
        issue1.metrics.update!(first_added_to_board_at: 3.days.ago, first_mentioned_in_commit_at: 2.days.ago)
        issue2.metrics.update!(first_added_to_board_at: 3.days.ago, first_mentioned_in_commit_at: 2.days.ago)
      end

      context 'when records are loaded by guest' do
        before do
          project.add_member(user, Gitlab::Access::GUEST)
        end

        it 'filters out confidential issues' do
          expect(subject.size).to eq(1)
          expect(subject.first[:iid].to_s).to eq(issue1.iid.to_s)
        end
      end

      include_context 'when records are loaded by maintainer'
    end

    describe 'for merge request based stage' do
      let(:mr1) { create(:merge_request, created_at: 5.days.ago, source_project: project, allow_broken: true) }
      let(:mr2) { create(:merge_request, created_at: 4.days.ago, source_project: project, allow_broken: true) }
      let(:stage) do
        build(:cycle_analytics_stage, {
          start_event_identifier: :merge_request_created,
          end_event_identifier: :merge_request_merged,
          project: project
        })
      end

      before do
        mr1.metrics.update!(merged_at: 3.days.ago)
        mr2.metrics.update!(merged_at: 3.days.ago)
      end

      include_context 'when records are loaded by maintainer'
    end
  end

  describe 'pagination' do
    let_it_be(:issue1) { create(:issue, project: project) }
    let_it_be(:issue2) { create(:issue, project: project) }
    let_it_be(:issue3) { create(:issue, project: project) }

    let(:stage) do
      build(:cycle_analytics_stage, {
        start_event_identifier: :plan_stage_start,
        end_event_identifier: :issue_first_mentioned_in_commit,
        namespace: project.project_namespace
      })
    end

    before_all do
      issue1.metrics.update!(first_added_to_board_at: 3.days.ago, first_mentioned_in_commit_at: 2.days.ago)
      issue2.metrics.update!(first_added_to_board_at: 3.days.ago, first_mentioned_in_commit_at: 2.days.ago)
      issue3.metrics.update!(first_added_to_board_at: 3.days.ago, first_mentioned_in_commit_at: 2.days.ago)
    end

    before do
      project.add_member(user, Gitlab::Access::DEVELOPER)

      stub_const('Gitlab::Analytics::CycleAnalytics::RecordsFetcher::MAX_RECORDS', 2)
    end

    it 'limits the results' do
      expect(subject.size).to eq(2)
    end

    it 'loads the record for the next page' do
      params[:page] = 2

      expect(subject.size).to eq(1)
    end
  end
end
