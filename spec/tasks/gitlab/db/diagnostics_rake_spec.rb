# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:diagnostics', :silence_stdout, feature_category: :database do
  let(:non_shared_database_names) do
    Gitlab::Database.database_base_models
      .reject { |_, model| Gitlab::Database.db_config_share_with(model.connection_db_config) }
      .keys
  end

  before do
    Rake.application.rake_require 'tasks/gitlab/db/diagnostics'
  end

  context 'with stubbed diagnostics' do
    before do
      allow(Gitlab::Database::Diagnostics::Console).to receive(:run).and_return(result)
    end

    let(:result) { nil }

    it 'reports on every database that does not share a cluster' do
      expect(Gitlab::Database::Diagnostics::Console)
        .to receive(:run).with(database_names: non_shared_database_names, check_names: nil)

      run_rake_task('gitlab:db:diagnostics')
    end

    it 'passes through the requested databases' do
      skip_if_multiple_databases_not_setup(:ci)

      expect(Gitlab::Database::Diagnostics::Console)
        .to receive(:run).with(database_names: %w[main ci], check_names: nil)

      run_rake_task('gitlab:db:diagnostics', 'main', 'ci')
    end

    it 'succeeds when nothing is found' do
      expect { run_rake_task('gitlab:db:diagnostics') }.not_to raise_error
    end

    context 'when only warnings are found' do
      let(:result) { 'warning' }

      it 'still succeeds' do
        expect { run_rake_task('gitlab:db:diagnostics') }.not_to raise_error
      end
    end

    context 'when an error is found' do
      let(:result) { 'error' }

      it 'exits with a non-zero status' do
        expect { run_rake_task('gitlab:db:diagnostics') }
          .to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end
  end

  describe 'per-check tasks' do
    it 'defines one task per registered check and no stale tasks' do
      check_tasks = Rake::Task.tasks.map(&:name)
        .select { |name| name.start_with?('gitlab:db:diagnostics:') }
        .map { |name| name.delete_prefix('gitlab:db:diagnostics:') }

      expect(check_tasks).to match_array(Gitlab::Database::Diagnostics::Console::VIEWS.keys)
    end

    it 'runs only its own check' do
      expect(Gitlab::Database::Diagnostics::Console)
        .to receive(:run).with(database_names: %w[main], check_names: %w[search_path])

      run_rake_task('gitlab:db:diagnostics:search_path', 'main')
    end
  end

  context 'with an unknown database name' do
    it 'aborts without running the diagnostics' do
      expect(Gitlab::Database::Diagnostics::Console).not_to receive(:run)

      expect { run_rake_task('gitlab:db:diagnostics', 'nope') }.to raise_error(SystemExit)
    end
  end

  it 'renders a report for the real database' do
    run_rake_task('gitlab:db:diagnostics', 'main')

    expect($stdout.string).to include('Database diagnostics', '== Search path ==', '== Summary ==')
  end
end
