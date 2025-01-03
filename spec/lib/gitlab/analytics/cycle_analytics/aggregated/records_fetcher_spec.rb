# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Aggregated::RecordsFetcher, feature_category: :value_stream_management do
  let_it_be(:project, refind: true) { create(:project, :public) }
  let_it_be(:issue_1) { create(:issue, project: project) }
  let_it_be(:issue_2) { create(:issue, :confidential, project: project) }
  let_it_be(:issue_3) { create(:issue, project: project) }

  let_it_be(:merge_request) { create(:merge_request, :unique_branches, source_project: project, target_project: project) }

  let_it_be(:user) { create(:user, developer_of: project) }

  let_it_be(:stage) { create(:cycle_analytics_stage, start_event_identifier: :issue_created, end_event_identifier: :issue_deployed_to_production, namespace: project.reload.project_namespace) }

  let_it_be(:stage_event_1) { create(:cycle_analytics_issue_stage_event, stage_event_hash_id: stage.stage_event_hash_id, project_id: project.id, issue_id: issue_1.id, start_event_timestamp: 2.years.ago, end_event_timestamp: 1.year.ago) } # duration: 1 year
  let_it_be(:stage_event_2) { create(:cycle_analytics_issue_stage_event, stage_event_hash_id: stage.stage_event_hash_id, project_id: project.id, issue_id: issue_2.id, start_event_timestamp: 5.years.ago, end_event_timestamp: 2.years.ago) } # duration: 3 years
  let_it_be(:stage_event_3) { create(:cycle_analytics_issue_stage_event, stage_event_hash_id: stage.stage_event_hash_id, project_id: project.id, issue_id: issue_3.id, start_event_timestamp: 6.years.ago, end_event_timestamp: 3.months.ago) } # duration: 5+ years

  let(:params) { { from: 10.years.ago, to: Date.today, current_user: user } }

  subject(:records_fetcher) do
    query_builder = Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder.new(stage: stage, params: params)
    described_class.new(stage: stage, query: query_builder.build_sorted_query, params: params)
  end

  shared_examples 'match returned records' do
    it 'returns issues in the correct order' do
      returned_iids = records_fetcher.serialized_records.pluck(:iid).map(&:to_i)

      expect(returned_iids).to eq(expected_iids)
    end

    it 'passes a hash with all expected attributes to the serializer' do
      expected_attributes = [
        'created_at',
        'id',
        'iid',
        'title',
        :end_event_timestamp,
        :start_event_timestamp,
        :total_time,
        :author,
        :namespace_path,
        :project_path
      ]
      serializer = instance_double(records_fetcher.send(:serializer).class.name)
      allow(records_fetcher).to receive(:serializer).and_return(serializer)
      expect(serializer).to receive(:represent).at_least(:once).with(hash_including(*expected_attributes)).and_return({})

      records_fetcher.serialized_records
    end
  end

  describe '#serialized_records' do
    describe 'sorting' do
      context 'when sorting by end event DESC' do
        let(:expected_iids) { [issue_3.iid, issue_1.iid, issue_2.iid] }

        before do
          params[:sort] = :end_event
          params[:direction] = :desc
        end

        it_behaves_like 'match returned records'
      end

      context 'when intervalstyle setting is configured to "postgres"' do
        it 'avoids nil durations' do
          # ActiveRecord cannot parse the 'postgres' intervalstyle, it returns nil
          # The setting is rolled back after the test case.
          Analytics::CycleAnalytics::IssueStageEvent.connection.execute("SET LOCAL intervalstyle='postgres'")

          records_fetcher.serialized_records do |relation|
            durations = relation.map(&:total_time)
            expect(durations).to all(be > 0)
          end
        end
      end

      context 'when sorting by end event ASC' do
        let(:expected_iids) { [issue_2.iid, issue_1.iid, issue_3.iid] }

        before do
          params[:sort] = :end_event
          params[:direction] = :asc
        end

        it_behaves_like 'match returned records'
      end

      context 'when sorting by duration DESC' do
        let(:expected_iids) { [issue_3.iid, issue_2.iid, issue_1.iid] }

        before do
          params[:sort] = :duration
          params[:direction] = :desc
        end

        it_behaves_like 'match returned records'
      end

      context 'when sorting by duration ASC' do
        let(:expected_iids) { [issue_1.iid, issue_2.iid, issue_3.iid] }

        before do
          params[:sort] = :duration
          params[:direction] = :asc
        end

        it_behaves_like 'match returned records'
      end
    end

    describe 'pagination' do
      let(:expected_iids) { [issue_3.iid] }

      before do
        params[:sort] = :duration
        params[:direction] = :asc
        params[:page] = 2

        stub_const('Gitlab::Analytics::CycleAnalytics::Aggregated::RecordsFetcher::MAX_RECORDS', 2)
      end

      it_behaves_like 'match returned records'
    end

    context 'when passing a block to serialized_records method' do
      before do
        params[:sort] = :duration
        params[:direction] = :asc
      end

      it 'yields the underlying stage event scope' do
        stage_event_records = []

        records_fetcher.serialized_records do |scope|
          stage_event_records.concat(scope.to_a)
        end

        expect(stage_event_records.map(&:issue_id)).to eq([issue_1.id, issue_2.id, issue_3.id])
      end
    end

    context 'when the issue record no longer exists' do
      it 'skips non-existing issue records' do
        create(:cycle_analytics_issue_stage_event, {
          issue_id: 0, # non-existing id
          stage_event_hash_id: stage.stage_event_hash_id,
          project_id: project.id,
          start_event_timestamp: 5.months.ago,
          end_event_timestamp: 3.months.ago
        })

        stage_event_count = nil

        records_fetcher.serialized_records do |scope|
          stage_event_count = scope.to_a.size
        end

        issue_count = records_fetcher.serialized_records.to_a.size

        expect(stage_event_count).to eq(4)
        expect(issue_count).to eq(3)
      end
    end
  end

  describe 'respecting visibility rules' do
    let(:expected_iids) { [issue_3.iid, issue_1.iid] }

    subject(:returned_iids) { records_fetcher.serialized_records.pluck(:iid).map(&:to_i) }

    context 'when current user is guest' do
      before do
        params[:current_user] = nil
      end

      it { is_expected.to eq(expected_iids) }
    end

    context 'when current user is logged and has no access to the project' do
      before do
        params[:current_user] = create(:user)
      end

      it { is_expected.to eq(expected_iids) }
    end
  end

  context 'when querying merge requests' do
    let_it_be(:mr_stage) { create(:cycle_analytics_stage, start_event_identifier: :merge_request_last_build_started, end_event_identifier: :merge_request_last_build_finished, namespace: project.reload.project_namespace) }
    let_it_be(:mr_stage_event) { create(:cycle_analytics_merge_request_stage_event, stage_event_hash_id: mr_stage.stage_event_hash_id, project_id: project.id, merge_request_id: merge_request.id, start_event_timestamp: 2.years.ago, end_event_timestamp: 1.year.ago) }

    let(:stage) { mr_stage }
    let(:expected_iids) { [merge_request.iid] }

    subject(:returned_iids) { records_fetcher.serialized_records.pluck(:iid).map(&:to_i) }

    it { is_expected.to eq(expected_iids) }

    context 'when current user is guest' do
      before do
        params[:current_user] = nil
      end

      it { is_expected.to eq([merge_request.iid]) }
    end

    context 'when current user is logged and has no access to the project' do
      before do
        params[:current_user] = create(:user)
      end

      it { is_expected.to eq([merge_request.iid]) }

      context 'when MR access level is elevated' do
        before do
          project.project_feature.update!(
            builds_access_level: ProjectFeature::PRIVATE,
            repository_access_level: ProjectFeature::PRIVATE,
            merge_requests_access_level: ProjectFeature::PRIVATE
          )
        end

        it { is_expected.to eq([]) }
      end
    end
  end
end
