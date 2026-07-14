# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::SiphonFinishedBuildsFinder, :click_house, :freeze_time,
  feature_category: :fleet_visibility do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_path) { project.project_namespace.traversal_path(with_organization: true) }
  let(:instance) { described_class.new }

  describe '#to_sql' do
    subject(:sql) { query.to_sql }

    context 'with the bare finder (no #select)' do
      let(:query) { instance }

      it 'emits a CTE-wrapped dedup + soft-delete + Ci::Build + finished-status filter shape' do
        ts = '`siphon_p_ci_builds`.`_siphon_replicated_at`'
        statuses = described_class::FINISHED_STATUSES.map { |s| "'#{s}'" }.join(', ')
        expected_sql =
          'WITH finished_builds AS (' \
            'SELECT `siphon_p_ci_builds`.`id`, `siphon_p_ci_builds`.`partition_id`, ' \
            "argMax(`siphon_p_ci_builds`.`traversal_path`, #{ts}) AS traversal_path, " \
            "argMax(`siphon_p_ci_builds`.`commit_id`, #{ts}) AS commit_id, " \
            "argMax(`siphon_p_ci_builds`.`name`, #{ts}) AS name, " \
            "argMax(`siphon_p_ci_builds`.`stage_id`, #{ts}) AS stage_id, " \
            "argMax(`siphon_p_ci_builds`.`started_at`, #{ts}) AS started_at, " \
            "argMax(`siphon_p_ci_builds`.`finished_at`, #{ts}) AS finished_at, " \
            "argMax(`siphon_p_ci_builds`.`_siphon_deleted`, #{ts}) AS _siphon_deleted, " \
            "argMax(`siphon_p_ci_builds`.`type`, #{ts}) AS type, " \
            "argMax(`siphon_p_ci_builds`.`status`, #{ts}) AS status " \
            'FROM `siphon_p_ci_builds` GROUP BY id, partition_id) ' \
            'SELECT * FROM `finished_builds` ' \
            "WHERE `finished_builds`.`_siphon_deleted` = 0 AND `finished_builds`.`type` = 'Ci::Build' " \
            "AND `finished_builds`.`status` IN (#{statuses})"

        is_expected.to eq(expected_sql)
      end
    end

    context 'with #with_stages + #select(:name, :stage_name) — the stages LEFT JOIN' do
      let(:query) { instance.for_container(project).with_stages(project).select(:name, :stage_name) }

      it 'joins siphon_p_ci_stages scoped by traversal_path', :aggregate_failures do
        is_expected.to include('LEFT OUTER JOIN')
        is_expected.to include('`finished_builds`.`stage_id` = `stages`.`id`')
        is_expected.to include('`stages`.`name` AS stage_name')
        is_expected.to include("`siphon_p_ci_stages`.`traversal_path` = '#{project_path}'")
        is_expected.not_to include('IN (SELECT `finished_builds`.`stage_id`')
      end
    end

    describe 'selecting :stage_name without #with_stages' do
      it 'raises so misuse fails before emitting SQL against a missing alias' do
        expect { instance.for_container(project).select(:name, :stage_name).to_sql }
          .to raise_error(ArgumentError, /call #with_stages/)
      end
    end

    describe '.for_container' do
      let(:query) { described_class.for_container(project) }

      it 'builds a finder scoped to the container' do
        is_expected.to include("WHERE `siphon_p_ci_builds`.`traversal_path` = '#{project_path}'")
      end
    end

    describe '#for_container' do
      let(:query) { instance.for_container(container) }

      context 'with a project' do
        let(:container) { project }

        it 'matches the exact traversal_path' do
          is_expected.to include("WHERE `siphon_p_ci_builds`.`traversal_path` = '#{project_path}'")
        end
      end

      context 'with a group' do
        let_it_be(:group) { create(:group) }

        let(:group_path) { group.traversal_path(with_organization: true) }
        let(:container) { group }

        it 'matches the traversal_path prefix' do
          is_expected.to include(
            "WHERE startsWith(`siphon_p_ci_builds`.`traversal_path`, '#{group_path}')"
          )
        end
      end
    end

    describe '#select(:name)' do
      let(:query) { instance.for_container(project).select(:name) }

      it 'only argMaxes the requested columns plus the always-required ones', :aggregate_failures do
        is_expected.to include('argMax(`siphon_p_ci_builds`.`name`,')
        is_expected.to include(' AS name')
        is_expected.not_to include('argMax(`siphon_p_ci_builds`.`commit_id`')
        is_expected.to include('GROUP BY `finished_builds`.`name`')
        # _siphon_deleted, type and status are projected unconditionally by
        # final_query so the outer WHERE clause can filter on them.
        is_expected.to include('argMax(`siphon_p_ci_builds`.`_siphon_deleted`')
        is_expected.to include('argMax(`siphon_p_ci_builds`.`type`')
        is_expected.to include('argMax(`siphon_p_ci_builds`.`status`')
      end
    end

    describe '#select with disallowed column raises' do
      it 'rejects unknown columns' do
        expect { instance.select(:invalid_column) }
          .to raise_error(ArgumentError, /Cannot select columns: \[:invalid_column\]/)
      end
    end

    describe '#select with empty input is a no-op' do
      let(:query) { instance.select }

      it { is_expected.to eq(instance.to_sql) }
    end

    describe '#filter_by_job_name' do
      let(:query) { instance.for_container(project).filter_by_job_name('rspec') }

      it 'filters on the latest job name with a case-insensitive HAVING clause' do
        is_expected.to include(
          "HAVING argMax(`siphon_p_ci_builds`.`name`, " \
            "`siphon_p_ci_builds`.`_siphon_replicated_at`) ILIKE '%rspec%'"
        )
      end
    end

    describe '#within_dates' do
      let(:from_time) { Time.utc(2026, 1, 1) }
      let(:to_time)   { Time.utc(2026, 2, 1) }

      context 'with both bounds' do
        let(:query) { instance.for_container(project).within_dates(from_time, to_time) }

        it 'pushes both bounds into the inner WHERE for projection-driven pruning', :aggregate_failures do
          is_expected.to include(
            "`siphon_p_ci_builds`.`started_at` >= toDateTime64('2026-01-01 00:00:00', 6, 'UTC')"
          )
          is_expected.to include(
            "`siphon_p_ci_builds`.`started_at` < toDateTime64('2026-02-01 00:00:00', 6, 'UTC')"
          )
        end
      end

      context 'with only from_time' do
        let(:query) { instance.for_container(project).within_dates(from_time, nil) }

        it 'pushes only the lower bound into the inner WHERE', :aggregate_failures do
          is_expected.to include(
            "`siphon_p_ci_builds`.`started_at` >= toDateTime64('2026-01-01 00:00:00', 6, 'UTC')"
          )
          is_expected.not_to include("< toDateTime64('2026-02-01")
        end
      end

      context 'with only to_time' do
        let(:query) { instance.for_container(project).within_dates(nil, to_time) }

        it 'pushes only the upper bound into the inner WHERE', :aggregate_failures do
          is_expected.to include(
            "`siphon_p_ci_builds`.`started_at` < toDateTime64('2026-02-01 00:00:00', 6, 'UTC')"
          )
          is_expected.not_to include(">= toDateTime64('2026-01-01")
        end
      end

      context 'with both nil' do
        let(:query) { instance.for_container(project).within_dates(nil, nil) }

        it 'does not add any started_at predicate' do
          is_expected.not_to match(/`siphon_p_ci_builds`\.`started_at`\s*(>=|<)/)
        end
      end
    end

    describe '#limit and #offset' do
      it { expect(instance.for_container(project).limit(10).to_sql).to include('LIMIT 10') }
      it { expect(instance.for_container(project).offset(5).to_sql).to include('OFFSET 5') }
    end

    describe '#order_by an aggregated column' do
      let(:query) { instance.for_container(project).select(:name).mean_duration.order_by(:mean_duration, :desc) }

      it { is_expected.to match(/ORDER BY mean_duration DESC/) }
    end

    describe '#order_by stage_name' do
      let(:query) do
        instance.for_container(project).with_stages(project).select(:name, :stage_name).order_by(:stage_name, :asc)
      end

      it 'orders on the joined column' do
        is_expected.to include('ORDER BY `stages`.`name` ASC')
      end
    end

    describe '#group_by stage_name' do
      let(:query) { instance.for_container(project).with_stages(project).select(:name).group_by(:stage_name) }

      it 'joins stages and groups on the joined column', :aggregate_failures do
        is_expected.to include('LEFT OUTER JOIN')
        is_expected.to include('GROUP BY `finished_builds`.`name`, `stages`.`name`')
      end
    end

    describe '#mean_duration computes from timestamps (no `duration` column on siphon_p_ci_builds)' do
      let(:query) { instance.for_container(project).select(:name).mean_duration }

      it 'averages age("ms", started_at, finished_at) converted to seconds' do
        is_expected.to include(
          "round((avg(if(`finished_builds`.`started_at` IS NOT NULL AND " \
            "`finished_builds`.`finished_at` IS NOT NULL AND " \
            "`finished_builds`.`finished_at` > `finished_builds`.`started_at`, " \
            "age('ms', `finished_builds`.`started_at`, `finished_builds`.`finished_at`), NULL)) / 1000.0), 2) " \
            "AS mean_duration"
        )
      end
    end

    describe '#p95_duration computes from timestamps too' do
      let(:query) { instance.for_container(project).select(:name).p95_duration }

      it { is_expected.to include('quantile(0.95)(if(') }
    end

    describe '#filter_by_pipeline_attrs' do
      let(:source) { nil }
      let(:ref) { nil }
      let(:query) do
        instance.for_container(project)
          .filter_by_pipeline_attrs(container: project, from_time: 30.days.ago, source: source, ref: ref)
      end

      context 'with no source/ref filter' do
        it 'skips the pipeline subquery entirely' do
          is_expected.not_to include('siphon_p_ci_pipelines')
        end
      end

      context 'with source filter' do
        let(:source) { 'push' }

        it 'joins the pipeline subquery via commit_id IN (...)' do
          is_expected.to include(
            "`siphon_p_ci_builds`.`commit_id` IN (SELECT `pipelines`.`id` FROM"
          )
          is_expected.to include("`pipelines`.`source` = #{::Ci::Pipeline.sources['push']}")
        end
      end

      context 'with ref filter' do
        let(:ref) { 'main' }

        it { is_expected.to include("`pipelines`.`ref` = 'main'") }
      end

      context 'with both source and ref' do
        let(:source) { 'web' }
        let(:ref) { 'main' }

        it 'combines both pipeline predicates', :aggregate_failures do
          is_expected.to include("`pipelines`.`source` = #{::Ci::Pipeline.sources['web']}")
          is_expected.to include("`pipelines`.`ref` = 'main'")
        end
      end
    end

    describe '#where applies arbitrary conditions to the inner subquery' do
      let(:query) { instance.for_container(project).where(name: 'rspec') }

      it { is_expected.to include("`siphon_p_ci_builds`.`name` = 'rspec'") }
    end

    describe '#group_by with empty input is a no-op' do
      let(:query) { instance.for_container(project).group_by }

      it { is_expected.to eq(instance.for_container(project).to_sql) }
    end

    describe '#group_by with disallowed column raises' do
      it 'raises ArgumentError' do
        expect { instance.group_by(:bogus) }
          .to raise_error(ArgumentError, /Cannot group by column: bogus/)
      end
    end

    describe '#filter_by_pipeline_attrs with no from_time and no filters returns self unchanged' do
      let(:original) { instance.for_container(project) }

      it 'is a no-op' do
        new_finder = original.filter_by_pipeline_attrs(container: project)
        expect(new_finder.to_sql).to eq(original.to_sql)
      end
    end

    context 'when chained, exhibits immutability so receivers are not mutated' do
      it 'returns new instances and leaves the original unchanged', :aggregate_failures do
        original = instance.for_container(project)
        chained  = original.select(:name).filter_by_job_name('rspec').within_dates(1.day.ago, nil)

        expect(chained).not_to eq(original)
        expect(original.to_sql).not_to include('ILIKE')
        expect(original.to_sql).not_to include('started_at >=')
      end
    end
  end

  describe '#to_redacted_sql' do
    subject(:redacted_sql) { instance.for_container(project).within_dates(from_time, to_time).to_redacted_sql }

    let(:from_time) { Time.utc(2026, 1, 1) }
    let(:to_time) { Time.utc(2026, 2, 1) }

    it 'replaces literals with positional placeholders', :aggregate_failures do
      expect(redacted_sql).to include('$1')
      expect(redacted_sql).not_to include(project_path)
      expect(redacted_sql).not_to include('2026-01-01')
    end
  end

  describe '#execute' do
    include_context 'with CI job analytics test data', with_pipelines: true, with_siphon: true

    subject(:rows) { finder.execute }

    let(:finder) { instance.for_container(project).select(:name).total_count }
    let(:row_names) { rows.map { |row| row['name'] } }

    def row_for(name)
      rows.find { |row| row['name'] == name }
    end

    it 'aggregates finished Ci::Build rows by job name', :aggregate_failures do
      expect(row_names).to contain_exactly('compile', 'compile-slow', 'rspec', 'lint', 'ref-build', 'source-build')
      expect(row_for('compile')['total_count']).to eq(3)
      expect(row_for('rspec')['total_count']).to eq(3)
    end

    context 'with mean_duration' do
      let(:finder) { instance.for_container(project).select(:name).mean_duration }

      it 'computes the average in seconds from started_at/finished_at' do
        # rspec: (3s failed, 3s failed, 2s canceled) / 3 = 8/3 = ~2.67s
        expect(row_for('rspec')['mean_duration']).to be_within(0.1).of(2.67)
      end

      context 'when a finished build has no usable timestamps' do
        # Skipped (and some canceled) builds are in COMPLETED_STATUSES but carry a
        # null started_at, so they have no derivable duration.
        let_it_be(:timestampless_build) do
          create(:ci_build, :skipped, project: project, pipeline: pipeline, ci_stage: stage2,
            name: 'rspec', started_at: nil, finished_at: nil)
        end

        before do
          insert_ci_builds_to_siphon([timestampless_build])
        end

        it 'excludes it from mean_duration instead of counting it as zero' do
          # A zero-duration row would pull the rspec mean down to (3 + 3 + 2 + 0) / 4 = 2.0s.
          expect(row_for('rspec')['mean_duration']).to be_within(0.1).of(2.67)
        end

        it 'still counts the build as a finished row' do
          count_rows = instance.for_container(project).select(:name).total_count.execute
          rspec_row = count_rows.find { |row| row['name'] == 'rspec' }

          expect(rspec_row['total_count']).to eq(4)
        end
      end
    end

    context 'with success/failed rates' do
      let(:finder) { instance.for_container(project).select(:name).rate_of_success.rate_of_failed }

      it 'computes rates against the (success + failed) denominator', :aggregate_failures do
        # rspec: 0 success / (0 success + 2 failed) = 0%, failed = 100%
        expect(row_for('rspec')['rate_of_success']).to eq(0.0)
        expect(row_for('rspec')['rate_of_failed']).to eq(100.0)
      end
    end

    context 'with stage names joined' do
      let(:finder) do
        instance.for_container(project).with_stages(project).select(:name, :stage_name).total_count
      end

      it 'resolves stage_name through the stages join', :aggregate_failures do
        expect(row_for('compile')['stage_name']).to eq('build')
        expect(row_for('rspec')['stage_name']).to eq('test')
      end
    end

    context 'with a pipeline source filter' do
      let(:finder) do
        instance.for_container(project).select(:name).total_count
          .filter_by_pipeline_attrs(container: project, from_time: 1.day.ago, source: 'web')
      end

      it 'keeps only builds from matching pipelines' do
        expect(row_names).to contain_exactly('source-build')
      end
    end

    context 'with a pipeline ref filter' do
      let(:finder) do
        instance.for_container(project).select(:name).total_count
          .filter_by_pipeline_attrs(container: project, from_time: 1.day.ago, ref: 'feature-branch')
      end

      it 'keeps only builds from matching pipelines' do
        expect(row_names).to contain_exactly('ref-build')
      end
    end

    context 'with a date window' do
      let(:finder) do
        instance.for_container(project).select(:name).total_count.within_dates(from_time, to_time)
      end

      context 'when the window excludes every build' do
        let(:from_time) { base_time + 1.hour }
        let(:to_time) { base_time + 2.hours }

        it { is_expected.to be_empty }
      end

      context 'when the window includes the builds' do
        let(:from_time) { base_time - 1.minute }
        let(:to_time) { base_time + 1.hour }

        it 'returns the rows started within the window' do
          expect(row_names).to include('compile', 'rspec')
        end
      end
    end

    context 'when a build is soft-deleted via a newer replicated_at version' do
      before do
        insert_ci_builds_to_siphon(failed_builds, replicated_at: 1.minute.from_now, deleted: true)
      end

      it 'excludes the soft-deleted rows' do
        # 2 rspec failed builds are soft-deleted, leaving the 1 canceled rspec build.
        expect(row_for('rspec')['total_count']).to eq(1)
      end
    end

    context 'when a build has a non-finished latest status' do
      let_it_be(:running_build) do
        create(:ci_build, :running, project: project, pipeline: pipeline, ci_stage: stage1,
          name: 'deploy-running', started_at: base_time, finished_at: nil)
      end

      before do
        insert_ci_builds_to_siphon([running_build])
      end

      it 'excludes it, mirroring the legacy finished-only seeding flow' do
        expect(row_names).not_to include('deploy-running')
      end
    end

    context 'when the same build is re-replicated with a newer status' do
      before do
        # Flip one failed rspec build to canceled via a newer replicated_at version.
        replicated = failed_builds.first.dup.tap do |b|
          b.id = failed_builds.first.id
          b.status = 'canceled'
        end
        insert_ci_builds_to_siphon([replicated], replicated_at: 1.minute.from_now)
      end

      let(:finder) { instance.for_container(project).select(:name).rate_of_failed }

      it 'aggregates on the latest version' do
        # rspec failed builds: was 2, now 1 failed + 1 canceled (+ original canceled).
        # rate_of_failed denominator is (success + failed) = 1, so 1/1 = 100%.
        expect(row_for('rspec')['rate_of_failed']).to eq(100.0)
      end
    end
  end
end
