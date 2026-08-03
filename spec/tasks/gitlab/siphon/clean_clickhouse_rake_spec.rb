# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:siphon:clean_clickhouse', :click_house, :silence_stdout, feature_category: :database do
  include RakeHelpers

  let(:task_name) { 'gitlab:siphon:clean_clickhouse' }
  let(:tables_dir) { Dir.mktmpdir }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/siphon/setup'
    Rake::Task.define_task(:gitlab_environment)
  end

  before do
    Rake::Task[task_name].reenable

    # siphon_issues is a `Null` engine pass-through, work_items is where the data lands
    File.write(File.join(tables_dir, 'issues.yml'), <<~YAML)
      ---
      table: issues
      database: main
      replication_targets:
        - name: clickhouse_main
          target: siphon_issues
          dedup_by_table: work_items
    YAML

    File.write(File.join(tables_dir, 'events.yml'), <<~YAML)
      ---
      table: events
      database: main
      replication_targets:
        - name: clickhouse_main
          target: siphon_events
          downstream_materialized_views:
            - contributions_new
          dedup_by_columns_lookup_table: siphon_events_pg_pkey_ordered
    YAML

    File.write(File.join(tables_dir, 'other_store.yml'), <<~YAML)
      ---
      table: other_store
      database: main
      replication_targets:
        - name: some_other_store
          target: siphon_other_store
    YAML

    allow(Dir).to receive(:[]).and_call_original
    allow(Dir).to receive(:[]).with(Rails.root.join('db/siphon/tables/*.yml'))
      .and_return(Dir.glob(File.join(tables_dir, '*.yml')))
  end

  after do
    FileUtils.remove_entry(tables_dir)
  end

  def row_count(table)
    ClickHouse::Client.select("SELECT count() AS count FROM #{table}", :main).first['count']
  end

  def truncate_of(table)
    an_object_having_attributes(prepared_placeholders: { table: table })
  end

  context 'without FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE' do
    it 'aborts without touching ClickHouse' do
      allow(ClickHouse::Client).to receive(:execute).and_call_original

      expect { run_rake_task(task_name) }.to raise_error(SystemExit)
        .and output(/FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE=true/).to_stderr

      expect(ClickHouse::Client).not_to have_received(:execute)
    end
  end

  context 'with FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE=true' do
    before do
      stub_env('FORCE_CLEAN_SIPHON_TABLES_IN_CLICKHOUSE', 'true')
    end

    it 'truncates every clickhouse_main table', :aggregate_failures do
      ClickHouse::Client.execute('INSERT INTO work_items (id) VALUES (1)', :main)
      # MVs copy this into siphon_events_pg_pkey_ordered and contributions_new
      ClickHouse::Client.execute(
        "INSERT INTO siphon_events (id, action, target_type) VALUES (1, 5, '')", :main
      )

      expect { run_rake_task(task_name) }
        .to change { row_count('work_items') }.from(1).to(0)
        .and change { row_count('siphon_events') }.from(1).to(0)
        .and change { row_count('siphon_events_pg_pkey_ordered') }.from(1).to(0)
        .and change { row_count('contributions_new') }.from(1).to(0)
    end

    it 'prefers dedup_by_table over the Null engine target', :aggregate_failures do
      allow(ClickHouse::Client).to receive(:execute).and_call_original

      run_rake_task(task_name)

      expect(ClickHouse::Client).to have_received(:execute).with(truncate_of('work_items'), :main)
      expect(ClickHouse::Client).not_to have_received(:execute).with(truncate_of('siphon_issues'), :main)
    end

    it 'ignores targets for other replication stores' do
      allow(ClickHouse::Client).to receive(:execute).and_call_original

      run_rake_task(task_name)

      expect(ClickHouse::Client).not_to have_received(:execute).with(truncate_of('siphon_other_store'), :main)
    end

    context 'with SIPHON_TABLES' do
      it 'only truncates the listed tables', :aggregate_failures do
        stub_env('SIPHON_TABLES', 'work_items, siphon_events')

        ClickHouse::Client.execute('INSERT INTO work_items (id) VALUES (1)', :main)
        ClickHouse::Client.execute('INSERT INTO siphon_events (id) VALUES (1)', :main)

        expect { run_rake_task(task_name) }
          .to change { row_count('work_items') }.from(1).to(0)
          .and change { row_count('siphon_events') }.from(1).to(0)
          .and not_change { row_count('siphon_events_pg_pkey_ordered') }.from(1)
      end

      it 'aborts on a table that is not a Siphon target' do
        stub_env('SIPHON_TABLES', 'work_items,nope')

        expect { run_rake_task(task_name) }.to raise_error(SystemExit)
          .and output(/Not Siphon ClickHouse tables: nope/).to_stderr
      end
    end

    it 'aborts when the main ClickHouse database is not configured' do
      allow(ClickHouse::Client).to receive(:database_configured?).with(:main).and_return(false)

      expect { run_rake_task(task_name) }.to raise_error(SystemExit)
        .and output(/not configured/).to_stderr
    end
  end
end
