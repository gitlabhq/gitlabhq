# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_unused_partitioned_indexes'

RSpec.describe Keeps::CleanupUnusedPartitionedIndexes, feature_category: :database do
  let(:grafana_query) { instance_double(Keeps::Helpers::GrafanaUnusedIndexQuery) }
  let(:keep_list) { instance_double(Keeps::Helpers::IndexKeepList) }
  let(:foreign_key_indexes) { instance_double(Keeps::CleanupUnusedIndexes::ForeignKeyIndexes) }
  let(:migration_builder) { instance_double(described_class::MigrationBuilder) }
  let(:cluster_mapper) { instance_double(Keeps::CleanupUnusedIndexes::InstanceClusterMapper) }
  let(:clone_catalog) { instance_double(described_class::CloneCatalog) }

  let(:children) { %w[ci_builds_101_user_id_idx ci_builds_102_user_id_idx] }

  let(:index) do
    described_class::CloneCatalog::ParentIndex.new(
      schema: 'public',
      name: 'p_ci_builds_user_id_idx',
      tablename: 'p_ci_builds',
      definition: 'CREATE INDEX p_ci_builds_user_id_idx ON ONLY public.p_ci_builds USING btree (user_id)'
    )
  end

  subject(:keep) do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive_messages(
        ensure_test_db!: nil,
        test_db_connection: nil
      )
    end

    described_class.new
  end

  def expect_decision_log(pattern)
    logger = keep.instance_variable_get(:@logger)
    allow(logger).to receive(:puts)

    keep.each_identified_change { |c| c }

    expect(logger).to have_received(:puts).with(pattern)
  end

  def skip_log(reason)
    a_string_including(
      %(Index "p_ci_builds_user_id_idx" on table "p_ci_builds" was skipped with reason: #{reason})
    )
  end

  before do
    stub_env('GITLAB_GRAFANA_API_URL', 'https://dashboards.gitlab.net')
    stub_env('GITLAB_GRAFANA_DATASOURCE_UID', 'mimir-gitlab-gprd')
    stub_env('GITLAB_GRAFANA_ENV', 'gprd')
    stub_env('POSTGRES_AI_CONNECTION_STRING', 'host=clone dbname=gitlabhq_dblab')
    stub_env('POSTGRES_AI_PASSWORD', 'secret')

    allow(Keeps::Helpers::GrafanaUnusedIndexQuery).to receive(:new).and_return(grafana_query)
    allow(Keeps::Helpers::IndexKeepList).to receive(:new).and_return(keep_list)
    allow(Keeps::CleanupUnusedIndexes::ForeignKeyIndexes).to receive(:new).and_return(foreign_key_indexes)
    allow(Keeps::CleanupUnusedIndexes::InstanceClusterMapper).to receive(:new).and_return(cluster_mapper)
    allow(described_class::MigrationBuilder).to receive(:new).and_return(migration_builder)
    allow(described_class::CloneCatalog).to receive(:new).and_return(clone_catalog)

    allow(grafana_query).to receive(:available?).and_return(true)
    allow(keep_list).to receive(:exempt?).and_return(false)
    allow(foreign_key_indexes).to receive(:include?).and_return(false)
    allow(cluster_mapper).to receive(:for_schema).and_return('patroni-ci')
    allow(clone_catalog).to receive_messages(
      candidate_parent_indexes: [index],
      child_index_names: children,
      index_columns: [:user_id],
      close: nil
    )

    dictionary_entry = instance_double(Gitlab::Database::Dictionary::Entry, gitlab_schema: 'gitlab_ci')
    allow(keep).to receive(:dictionary_entry).with('p_ci_builds').and_return(dictionary_entry)
  end

  describe '#each_identified_change' do
    context 'when Grafana credentials are missing' do
      before do
        allow(grafana_query).to receive(:available?).and_return(false)
      end

      it 'raises a clear error' do
        expect { |b| keep.each_identified_change(&b) }
          .to raise_error(/Grafana credentials missing/)
      end
    end

    context 'when clone credentials are missing' do
      before do
        stub_env('POSTGRES_AI_CONNECTION_STRING', '')
      end

      it 'raises a clear error' do
        expect { |b| keep.each_identified_change(&b) }
          .to raise_error(/clone credentials missing/)
      end
    end

    context 'when every child index is confirmed unused' do
      before do
        allow(grafana_query).to receive(:scans_by_index)
          .with(indexrelnames: children, type: 'patroni-ci')
          .and_return(children.index_with { |_| 0.0 })
      end

      it 'yields a change with stable identifiers and context', :aggregate_failures do
        changes = []
        keep.each_identified_change { |c| changes << c }

        expect(changes.size).to eq(1)
        expect(changes.first.identifiers).to eq(%w[CleanupUnusedPartitionedIndexes public p_ci_builds_user_id_idx])
        expect(changes.first.context).to include(
          schema: 'public',
          name: 'p_ci_builds_user_id_idx',
          tablename: 'p_ci_builds',
          gitlab_schema: 'gitlab_ci',
          cluster_type: 'patroni-ci',
          checked_at: an_instance_of(String),
          columns: [:user_id],
          child_index_names: children
        )
      end

      it 'logs the selected decision with the child count' do
        expect_decision_log(
          a_string_including('was selected with reason: zero scans across 2 child indexes')
        )
      end

      it 'closes the clone connection when the scan finishes' do
        keep.each_identified_change { |c| c }

        expect(clone_catalog).to have_received(:close)
      end
    end

    context 'when any child index has scans' do
      before do
        allow(grafana_query).to receive(:scans_by_index)
          .and_return('ci_builds_101_user_id_idx' => 0.0, 'ci_builds_102_user_id_idx' => 7.0)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'skips silently to keep the job log free of in-use index noise' do
        logger = keep.instance_variable_get(:@logger)
        allow(logger).to receive(:puts)

        keep.each_identified_change { |c| c }

        expect(logger).not_to have_received(:puts)
      end
    end

    context 'when a child index has no Mimir series' do
      before do
        allow(grafana_query).to receive(:scans_by_index)
          .and_return('ci_builds_101_user_id_idx' => 0.0)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(skip_log('no usage signal for 1 of 2 child indexes; skipping conservatively'))
      end
    end

    context 'when Mimir returns no signal' do
      before do
        allow(grafana_query).to receive(:scans_by_index).and_return(nil)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(skip_log('no usage signal from Mimir; skipping conservatively'))
      end
    end

    context 'when the parent has no child partition indexes on the clone' do
      before do
        allow(clone_catalog).to receive(:child_index_names).and_return([])
      end

      it 'does not yield and skips the Grafana query', :aggregate_failures do
        expect(grafana_query).not_to receive(:scans_by_index)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(skip_log('no child partition indexes found on the clone'))
      end
    end

    context 'when the table belongs to a shared gitlab schema' do
      before do
        dictionary_entry = instance_double(
          Gitlab::Database::Dictionary::Entry, gitlab_schema: 'gitlab_shared_cell_local'
        )
        allow(keep).to receive(:dictionary_entry).with('p_ci_builds').and_return(dictionary_entry)
      end

      it 'does not yield and skips the Grafana query', :aggregate_failures do
        expect(grafana_query).not_to receive(:scans_by_index)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(
          skip_log('gitlab_shared_cell_local tables exist on every database; ' \
            'usage cannot be attributed to one cluster')
        )
      end
    end

    context 'when the definition cannot be rebuilt by the down migration' do
      let(:index) do
        described_class::CloneCatalog::ParentIndex.new(
          schema: 'public',
          name: 'p_ci_builds_user_id_idx',
          tablename: 'p_ci_builds',
          definition: 'CREATE INDEX p_ci_builds_user_id_idx ON ONLY public.p_ci_builds ' \
            'USING btree (user_id, created_at DESC)'
        )
      end

      it 'does not yield and skips the Grafana query', :aggregate_failures do
        expect(grafana_query).not_to receive(:scans_by_index)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(skip_log('definition has ordering or options the down migration cannot rebuild'))
      end
    end

    context 'when the table has no dictionary entry in this checkout' do
      before do
        allow(keep).to receive(:dictionary_entry).with('p_ci_builds').and_return(nil)
      end

      it 'does not yield and skips the Grafana query', :aggregate_failures do
        expect(grafana_query).not_to receive(:scans_by_index)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(skip_log('table has no db/docs dictionary entry in this checkout'))
      end
    end

    context 'when the index is in the keep list' do
      before do
        allow(keep_list).to receive(:exempt?).with('public', 'p_ci_builds_user_id_idx').and_return(true)
      end

      it 'does not yield and skips the Grafana query', :aggregate_failures do
        expect(grafana_query).not_to receive(:scans_by_index)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(skip_log('exempt via index_keep_list.yml'))
      end
    end

    context 'when the index supports a foreign key' do
      before do
        allow(foreign_key_indexes).to receive(:include?).with('public.p_ci_builds_user_id_idx').and_return(true)
      end

      it 'does not yield', :aggregate_failures do
        expect(grafana_query).not_to receive(:scans_by_index)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end

      it 'logs the skip decision' do
        expect_decision_log(skip_log('supports a foreign key'))
      end
    end
  end

  describe '#make_change!' do
    let(:migration_file) { 'db/post_migrate/20260701000000_remove_unused_index_p_ci_builds_user_id_idx.rb' }
    let(:built_result) do
      described_class::MigrationBuilder::Result.new(
        migration_file: migration_file,
        migration_number: '20260701000000',
        digest_file: 'db/schema_migrations/20260701000000'
      )
    end

    let(:change) do
      ::Gitlab::Housekeeper::Change.new.tap do |c|
        c.identifiers = %w[CleanupUnusedPartitionedIndexes public p_ci_builds_user_id_idx]
        c.context = {
          schema: 'public',
          name: 'p_ci_builds_user_id_idx',
          tablename: 'p_ci_builds',
          gitlab_schema: 'gitlab_ci',
          cluster_type: 'patroni-ci',
          checked_at: '2026-07-17T09:00:00Z',
          definition: 'CREATE INDEX p_ci_builds_user_id_idx ON ONLY p_ci_builds USING btree (user_id)',
          columns: [:user_id],
          child_index_names: children
        }
      end
    end

    before do
      allow(migration_builder).to receive(:build).with(change.context).and_return(built_result)
      allow(keep).to receive_messages(
        migrate: nil,
        reset_db: nil,
        labels: %w[group::ci maintenance::removal],
        pick_assignee: 'engineer-handle'
      )
    end

    it 'returns a Change with the expected fields', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result).to be_a(::Gitlab::Housekeeper::Change)
      expect(result.title).to eq('Remove unused partitioned index p_ci_builds_user_id_idx')
      expect(result.changed_files).to contain_exactly(
        migration_file,
        'db/schema_migrations/20260701000000',
        'db/structure.sql'
      )
      expect(result.labels).to eq(%w[group::ci maintenance::removal])
      expect(result.assignees).to eq(['engineer-handle'])
      expect(result.reviewers).to be_blank
    end

    it 'renders the partitioned-specific description', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result.description).to include('CREATE INDEX p_ci_builds_user_id_idx')
      expect(result.description).to include('All 2 child partition indexes')
      expect(result.description).to include('query run at 2026-07-17T09:00:00Z')
      expect(result.description).to include('cascades to **every partition**')
      expect(result.description).to include('There is no asynchronous removal path')
      expect(result.description).to include('- `ci_builds_101_user_id_idx`')
      expect(result.description).to include('- `ci_builds_102_user_id_idx`')
      expect(result.description).to include('keeps/cleanup_unused_indexes/index_keep_list.yml')
    end

    it 'embeds a Grafana Explore deep link summing the child indexes', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result.description).to include('https://dashboards.gitlab.net/explore?')
      expect(CGI.unescape(result.description)).to include('ci_builds_101_user_id_idx|ci_builds_102_user_id_idx')
      expect(CGI.unescape(result.description)).to include('type=\"patroni-ci\"')
    end
  end
end
