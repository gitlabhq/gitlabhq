# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::FinishedBuildsDeduplicatedFinder, :click_house, :freeze_time, feature_category: :fleet_visibility do
  include_context 'with CI job analytics test data'

  let(:instance) { described_class.new }

  it_behaves_like 'finished builds finder select behavior'
  it_behaves_like 'finished builds finder aggregations'
  it_behaves_like 'finished builds finder ordering'
  it_behaves_like 'finished builds finder offset'
  it_behaves_like 'finished builds finder grouping'
  it_behaves_like 'finished builds finder filters'
  it_behaves_like 'finished builds finder method chaining'
  it_behaves_like 'finished builds finder execution'

  describe 'deduplication behavior' do
    context 'with duplicate records (same id, different versions)' do
      let_it_be(:dedup_build_id) { 999_999 }
      let_it_be(:base_build_attrs) do
        {
          id: 999_999,
          project: project,
          pipeline: pipeline,
          ci_stage: stage1,
          started_at: base_time,
          finished_at: base_time + 1.second
        }
      end

      let_it_be(:original_build) do
        build_stubbed(:ci_build, :success, **base_build_attrs, name: 'original-name')
      end

      let_it_be(:updated_build) do
        build_stubbed(:ci_build, :failed, **base_build_attrs, name: 'updated-name',
          finished_at: base_time + 2.seconds)
      end

      before do
        insert_ci_builds_to_click_house([original_build], version: 1.hour.ago)
        insert_ci_builds_to_click_house([updated_build], version: Time.current)
      end

      describe 'returns only the latest version' do
        subject do
          instance.for_project(project.id)
            .where(id: dedup_build_id)
            .select(:name)
            .execute
            .pluck('name')
        end

        it { is_expected.to include('updated-name') }
        it { is_expected.not_to include('original-name') }
      end

      describe 'uses the latest status for aggregations' do
        subject(:rate_of_failed) do
          instance.for_project(project.id)
            .where(id: dedup_build_id)
            .select(:name)
            .rate_of_failed
            .execute
        end

        it { expect(rate_of_failed.find { |r| r['name'] == 'updated-name' }['rate_of_failed']).to eq(100.0) }
      end

      describe 'uses the latest duration for calculations' do
        subject(:mean_duration) do
          instance.for_project(project.id)
            .where(id: dedup_build_id)
            .select(:name)
            .mean_duration
            .execute
        end

        it { expect(mean_duration.find { |r| r['name'] == 'updated-name' }['mean_duration']).to eq(2.0) }
      end
    end

    describe 'SQL structure' do
      it 'generates subquery structure with argMax' do
        expected_sql = <<~SQL.squish
          SELECT
              `finished_builds`.`name`,
              round((avg(`finished_builds`.`duration`) / 1000.0), 2) AS mean_duration
          FROM
          (SELECT
              `ci_finished_builds`.`id`,
              argMax(`ci_finished_builds`.`name`, `ci_finished_builds`.`version`) AS name,
              argMax(`ci_finished_builds`.`duration`, `ci_finished_builds`.`version`) AS duration
          FROM `ci_finished_builds`
          WHERE `ci_finished_builds`.`project_id` = #{project.id}
          GROUP BY id) finished_builds
          GROUP BY `finished_builds`.`name`
        SQL

        sql = instance.for_project(project.id).select(:name).mean_duration.to_sql
        expect(sql).to eq(expected_sql)
      end
    end
  end

  describe '#filter_deleted' do
    let_it_be(:build_attrs) do
      {
        project: project,
        pipeline: pipeline,
        ci_stage: stage1,
        started_at: base_time,
        finished_at: base_time + 1.second
      }
    end

    let_it_be(:active_build, freeze: true) do
      create(:ci_build, :success, **build_attrs, name: 'active-build')
    end

    let_it_be(:deleted_build, freeze: true) do
      create(:ci_build, :success, **build_attrs, name: 'deleted-build')
    end

    before do
      insert_ci_builds_to_click_house([active_build], deleted: false)
      insert_ci_builds_to_click_house([deleted_build], deleted: true)
    end

    describe 'filtering behavior' do
      subject do
        instance.for_project(project.id)
          .filter_deleted(include_deleted: include_deleted)
          .select(:name)
          .execute
          .pluck('name')
      end

      context 'when include_deleted is false' do
        let(:include_deleted) { false }

        it { is_expected.to include('active-build') }
        it { is_expected.not_to include('deleted-build') }
      end

      context 'when include_deleted is true' do
        let(:include_deleted) { true }

        it { is_expected.to include('active-build', 'deleted-build') }
      end
    end

    it 'applies HAVING clause for deleted filter' do
      sql = instance.for_project(project.id).filter_deleted.to_sql

      expect(sql).to include('HAVING')
      expect(sql).to include('deleted')
    end
  end

  describe '#filter_by_job_name with HAVING' do
    it 'applies job name filter via HAVING clause' do
      sql = instance.for_project(project.id)
        .filter_by_job_name('compile')
        .to_sql

      expect(sql).to include('HAVING')
      expect(sql).to include('ILIKE')
      expect(sql).to include('%compile%')
    end
  end
end
