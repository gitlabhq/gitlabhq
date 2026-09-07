# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:siphon:check_replication_slots', :silence_stdout, feature_category: :database do
  include RakeHelpers

  let(:task_name) { 'gitlab:siphon:check_replication_slots' }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:slot_names) { 'siphon_slot_main_db' }

  # One entry per select_all call: the first is the baseline, the rest are polling rounds. The last
  # entry repeats once the list runs out.
  let(:readings) { [[slot_row], [slot_row(bytes: 2000)]] }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/siphon/setup'
    Rake::Task.define_task(:gitlab_environment)
  end

  before do
    Rake::Task[task_name].reenable

    stub_env('SIPHON_SLOT_NAMES', slot_names)
    allow(Kernel).to receive(:sleep)
    allow(Gitlab::Database::EachDatabase).to receive(:each_connection).and_yield(connection, 'main')

    stub_connection(connection, *readings)
  end

  def stub_connection(conn, *rows)
    allow(conn).to receive(:quote) { |value| "'#{value}'" }
    allow(conn).to receive(:transaction).and_yield
    allow(conn).to receive(:select_all).and_return(*rows)
  end

  def slot_row(active: true, wal_status: 'reserved', bytes: 1000)
    {
      'slot_name' => 'siphon_slot_main_db',
      'active' => active,
      'wal_status' => wal_status,
      'lsn' => bytes && "0/#{bytes.to_s(16).upcase}",
      'lsn_bytes' => bytes
    }
  end

  it 'only looks at the slots bound to the database being checked' do
    run_rake_task(task_name)

    expect(connection).to have_received(:select_all).with(
      a_string_including('FROM pg_catalog.pg_replication_slots')
        .and(including('database = pg_catalog.current_database()'))
        .and(including("slot_name IN ('siphon_slot_main_db')"))
    ).at_least(:once)
  end

  it 'passes as soon as the slot advances', :aggregate_failures do
    expect { run_rake_task(task_name) }
      .to output(a_string_including('All 1 slots are active and advancing')).to_stdout

    expect(Kernel).to have_received(:sleep).once
  end

  it 'limits to one database when SIPHON_DATABASE is set' do
    stub_env('SIPHON_DATABASE', 'ci')

    run_rake_task(task_name)

    expect(Gitlab::Database::EachDatabase)
      .to have_received(:each_connection).with(only: 'ci', include_shared: false)
  end

  context 'when the slot never advances' do
    let(:readings) { [[slot_row]] }

    it 'warns but exits zero, since an idle database produces no WAL', :aggregate_failures do
      expect { run_rake_task(task_name) }
        .to output(/WARNING  siphon_slot_main_db \(main\): confirmed_flush_lsn did not advance in 25s/).to_stderr

      expect(Kernel).to have_received(:sleep).exactly(5).times
    end
  end

  context 'when confirmed_flush_lsn is NULL' do
    let(:readings) { [[slot_row(bytes: nil)]] }

    it 'counts as no progress' do
      expect { run_rake_task(task_name) }.to output(/WARNING  siphon_slot_main_db/).to_stderr
    end
  end

  context 'when the slot is inactive' do
    let(:readings) { [[slot_row(active: false)]] }

    it 'retries the whole window, then aborts', :aggregate_failures do
      expect { run_rake_task(task_name) }
        .to raise_error(SystemExit)
        .and output(/FAILED   siphon_slot_main_db: still inactive after 25s/).to_stderr

      expect(Kernel).to have_received(:sleep).exactly(5).times
    end

    context 'when the producer reconnects part way through' do
      let(:readings) { [[slot_row(active: false)], [slot_row(active: false)], [slot_row(bytes: 2000)]] }

      it 'passes', :aggregate_failures do
        expect { run_rake_task(task_name) }.not_to raise_error

        expect(Kernel).to have_received(:sleep).twice
      end
    end
  end

  context 'when wal_status is extended' do
    let(:readings) { [[slot_row(wal_status: 'extended')]] }

    it 'aborts' do
      expect { run_rake_task(task_name) }
        .to raise_error(SystemExit)
        .and output(/wal_status is extended, expected reserved/).to_stderr
    end
  end

  context 'when wal_status is lost' do
    let(:readings) { [[slot_row(wal_status: 'lost')]] }

    it 'gives up without waiting out the window', :aggregate_failures do
      expect { run_rake_task(task_name) }
        .to raise_error(SystemExit)
        .and output(/FAILED   siphon_slot_main_db: wal_status is lost/).to_stderr

      expect(Kernel).to have_received(:sleep).once
    end
  end

  context 'when the slot is in no database' do
    let(:readings) { [[]] }

    it 'aborts' do
      expect { run_rake_task(task_name) }
        .to raise_error(SystemExit)
        .and output(/FAILED   siphon_slot_main_db: not found in any database/).to_stderr
    end
  end

  context 'when the slot lives in another database' do
    let(:ci_connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    before do
      allow(Gitlab::Database::EachDatabase).to receive(:each_connection)
        .and_yield(connection, 'main').and_yield(ci_connection, 'ci')

      stub_connection(connection, [])
      stub_connection(ci_connection, [slot_row], [slot_row(bytes: 2000)])
    end

    it 'attributes it to that database' do
      expect { run_rake_task(task_name) }
        .to output(a_string_including('OK       siphon_slot_main_db (ci)')).to_stdout
    end
  end

  context 'when the same slot name exists on two databases' do
    let(:ci_connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    before do
      allow(Gitlab::Database::EachDatabase).to receive(:each_connection)
        .and_yield(connection, 'main').and_yield(ci_connection, 'ci')

      stub_connection(connection, [slot_row(active: false)])
      stub_connection(ci_connection, [slot_row], [slot_row(bytes: 2000)])
    end

    it 'does not let the healthy one hide the broken one' do
      expect { run_rake_task(task_name) }
        .to raise_error(SystemExit)
        .and output(/FAILED   siphon_slot_main_db: still inactive/).to_stderr
    end
  end

  context 'when SIPHON_SLOT_NAMES is not set' do
    let(:slot_names) { nil }

    it 'checks every slot with siphon in its name' do
      run_rake_task(task_name)

      expect(connection).to have_received(:select_all)
        .with(a_string_including("slot_name LIKE '%siphon%'")).once
    end

    context 'when no database has one' do
      let(:readings) { [[]] }

      it 'aborts' do
        expect { run_rake_task(task_name) }
          .to raise_error(SystemExit)
          .and output(/No slot matching %siphon% on any database/).to_stderr
      end
    end
  end
end
