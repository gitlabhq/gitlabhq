# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_unused_indexes'

RSpec.describe Keeps::CleanupUnusedIndexes, feature_category: :database do
  let(:grafana_query) { instance_double(Keeps::Helpers::GrafanaUnusedIndexQuery) }
  let(:keep_list) { instance_double(Keeps::Helpers::IndexKeepList) }
  let(:foreign_key_indexes) { instance_double(Keeps::CleanupUnusedIndexes::ForeignKeyIndexes) }
  let(:migration_builder) { instance_double(Keeps::CleanupUnusedIndexes::MigrationBuilder) }
  let(:cluster_mapper) { instance_double(Keeps::CleanupUnusedIndexes::InstanceClusterMapper) }

  let(:index) do
    instance_double(
      Gitlab::Database::PostgresIndex,
      identifier: 'public.index_users_on_foo',
      schema: 'public',
      name: 'index_users_on_foo',
      tablename: 'users',
      definition: 'CREATE INDEX index_users_on_foo ON public.users USING btree (foo)'
    )
  end

  subject(:keep) do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive_messages(
        ensure_test_db!: nil,
        test_db_connection: nil,
        candidate_indexes: [index],
        columns_for: [:foo]
      )
    end

    described_class.new
  end

  before do
    stub_env('GITLAB_GRAFANA_API_URL', 'https://dashboards.gitlab.net')
    stub_env('GITLAB_GRAFANA_DATASOURCE_UID', 'mimir-gitlab-gprd')
    stub_env('GITLAB_GRAFANA_ENV', 'gprd')

    allow(Keeps::Helpers::GrafanaUnusedIndexQuery).to receive(:new).and_return(grafana_query)
    allow(Keeps::Helpers::IndexKeepList).to receive(:new).and_return(keep_list)
    allow(Keeps::CleanupUnusedIndexes::ForeignKeyIndexes).to receive(:new).and_return(foreign_key_indexes)
    allow(Keeps::CleanupUnusedIndexes::MigrationBuilder).to receive(:new).and_return(migration_builder)
    allow(Keeps::CleanupUnusedIndexes::InstanceClusterMapper).to receive(:new).and_return(cluster_mapper)

    allow(grafana_query).to receive(:available?).and_return(true)
    allow(keep_list).to receive(:exempt?).and_return(false)
    allow(foreign_key_indexes).to receive(:include?).and_return(false)
    allow(cluster_mapper).to receive(:for_schema).and_return('patroni')

    dictionary_entry = instance_double(Gitlab::Database::Dictionary::Entry, gitlab_schema: 'gitlab_main')
    allow(keep).to receive(:dictionary_entry).with('users').and_return(dictionary_entry)
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

    context 'when the index is confirmed unused by Mimir' do
      before do
        allow(grafana_query).to receive(:unused?)
          .with(table: 'users', type: 'patroni', indexrelname: 'index_users_on_foo')
          .and_return(true)
      end

      it 'yields a change with stable identifiers and context', :aggregate_failures do
        changes = []
        keep.each_identified_change { |c| changes << c }

        expect(changes.size).to eq(1)
        expect(changes.first.identifiers).to eq(%w[CleanupUnusedIndexes public index_users_on_foo])
        expect(changes.first.context).to include(
          schema: 'public',
          name: 'index_users_on_foo',
          tablename: 'users',
          gitlab_schema: 'gitlab_main',
          cluster_type: 'patroni',
          columns: [:foo]
        )
      end
    end

    context 'when columns_for returns empty' do
      before do
        allow(grafana_query).to receive(:unused?).and_return(true)
        allow(keep).to receive(:columns_for).and_return([])
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when Mimir reports the index has activity' do
      before do
        allow(grafana_query).to receive(:unused?).and_return(false)
      end

      it 'does not yield' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when Mimir returns no signal (cap reached, no series, or unreachable)' do
      before do
        allow(grafana_query).to receive(:unused?).and_return(nil)
      end

      it 'does not yield (conservative skip)' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when the index is in the keep list' do
      before do
        allow(keep_list).to receive(:exempt?).with('public', 'index_users_on_foo').and_return(true)
      end

      it 'does not yield and skips the Grafana query', :aggregate_failures do
        expect(grafana_query).not_to receive(:unused?)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when the index supports a foreign key' do
      before do
        allow(foreign_key_indexes).to receive(:include?).with('public.index_users_on_foo').and_return(true)
      end

      it 'does not yield', :aggregate_failures do
        expect(grafana_query).not_to receive(:unused?)
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when build_change_for raises for one index' do
      let(:other_index) do
        instance_double(
          Gitlab::Database::PostgresIndex,
          identifier: 'public.index_users_on_bar',
          schema: 'public', name: 'index_users_on_bar', tablename: 'users',
          definition: 'CREATE INDEX ...'
        )
      end

      before do
        allow(keep).to receive_messages(
          candidate_indexes: [index, other_index],
          columns_for: [:foo]
        )
        allow(keep).to receive(:columns_for).with(other_index).and_return([:bar])
        allow(grafana_query).to receive(:unused?).and_return(true)
        allow(keep).to receive(:build_change_for).with(index).and_raise(StandardError, 'boom')
        allow(keep).to receive(:build_change_for).with(other_index).and_call_original
      end

      it 'logs the failure via @logger and continues to the next index', :aggregate_failures do
        logger = keep.instance_variable_get(:@logger)
        allow(logger).to receive(:puts)

        changes = []
        keep.each_identified_change { |c| changes << c }

        expect(logger).to have_received(:puts).with(/Skipping public.index_users_on_foo/)
        expect(changes.map { |c| c.context[:name] }).to eq(['index_users_on_bar'])
      end
    end
  end

  describe '#make_change!' do
    let(:migration_file) { 'db/post_migrate/20260601000000_async_remove_unused_index.rb' }
    let(:built_result) do
      Keeps::CleanupUnusedIndexes::MigrationBuilder::Result.new(
        migration_file: migration_file,
        migration_number: '20260601000000',
        digest_file: 'db/schema_migrations/20260601000000'
      )
    end

    let(:change) do
      ::Gitlab::Housekeeper::Change.new.tap do |c|
        c.identifiers = %w[CleanupUnusedIndexes public index_users_on_foo]
        c.context = {
          schema: 'public',
          name: 'index_users_on_foo',
          tablename: 'users',
          gitlab_schema: 'gitlab_main',
          cluster_type: 'patroni',
          definition: 'CREATE INDEX index_users_on_foo ON public.users USING btree (foo)',
          columns: [:foo]
        }
      end
    end

    before do
      allow(migration_builder).to receive(:build).with(change.context).and_return(built_result)
      allow(keep).to receive_messages(
        migrate: nil,
        reset_db: nil,
        labels: %w[group::foo maintenance::removal],
        pick_reviewer: 'engineer-handle'
      )
    end

    it 'returns a Change with the expected fields', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result).to be_a(::Gitlab::Housekeeper::Change)
      expect(result.title).to eq('Remove unused index index_users_on_foo')
      expect(result.changed_files).to contain_exactly(
        migration_file,
        'db/schema_migrations/20260601000000',
        'db/structure.sql'
      )
      expect(result.labels).to eq(%w[group::foo maintenance::removal])
      expect(result.reviewers).to eq(['engineer-handle'])
      expect(result.assignees).to be_blank
    end

    it 'regenerates db/structure.sql by applying the migration', :aggregate_failures do
      expect(keep).to receive(:migrate).ordered
      expect(keep).to receive(:reset_db).ordered

      keep.make_change!(change)
    end

    it 'renders the description with definition, 180d verification prompt, and escape hatch', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result.description).to include('CREATE INDEX index_users_on_foo')
      expect(result.description).to include('verify the 180-day Grafana chart')
      expect(result.description).to include('type="patroni"')
      expect(result.description).to include('[180d]')
      expect(result.description).to include('Cross-environment review checklist')
      expect(result.description).to include('keeps/cleanup_unused_indexes/index_keep_list.yml')
    end

    it 'interpolates the table and columns into the Kibana review step', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result.description).to include('pubsub-postgres-inf-gprd*')
      expect(result.description).to include('json.sql: users AND json.sql: *foo*')
      expect(result.description).to include('filters/orders on `foo`')
    end

    it 'warns to use asynchronous removal for large tables', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result.description).to include('Large tables: remove asynchronously instead')
      expect(result.description).to include('#drop-indexes-asynchronously')
    end

    it 'embeds a Grafana Explore deep link with the index name in the encoded PromQL', :aggregate_failures do
      result = keep.make_change!(change)

      expect(result.description).to include('https://dashboards.gitlab.net/explore?')
      expect(result.description).to include('Open this query in Grafana Explore')
      # The link must contain the encoded PromQL referencing this index.
      expect(CGI.unescape(result.description)).to include('indexrelname="index_users_on_foo"')
    end
  end

  describe '#labels' do
    let(:table_info) { instance_double(Gitlab::Database::Dictionary::Entry, feature_categories: ['shared']) }

    before do
      allow(keep).to receive(:dictionary_entry).with('users').and_return(table_info)
      allow(keep.send(:groups_helper)).to receive(:labels_for_feature_category)
        .with('shared').and_return(['group::foo'])
    end

    it 'combines group labels with the standard maintenance and review labels' do
      expect(keep.send(:labels, 'users')).to eq(
        ['group::foo', 'automation:cleanup-unused-indexes', 'maintenance::removal', 'type::maintenance',
          'Category:Database', 'pipeline::tier-1', 'database::review pending', 'workflow::in review']
      )
    end

    context 'when the dictionary has no entry for the table' do
      before do
        allow(keep).to receive(:dictionary_entry).with('users').and_return(nil)
      end

      it 'falls back to the standard maintenance and review labels only' do
        expect(keep.send(:labels, 'users')).to eq(
          ['automation:cleanup-unused-indexes', 'maintenance::removal', 'type::maintenance',
            'Category:Database', 'pipeline::tier-1', 'database::review pending', 'workflow::in review']
        )
      end
    end
  end
end
