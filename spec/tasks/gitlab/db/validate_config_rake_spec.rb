# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:validate_config', :silence_stdout, :suppress_gitlab_schemas_validate_connection, feature_category: :cell do
  # We don't need to delete this data since it only modifies `ar_internal_metadata`
  # which would not be cleaned either by `DbCleaner`
  self.use_transactional_tests = false

  before(:all) do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/db/validate_config'
  end

  context "when validating config" do
    let(:main_database_config) do
      Rails.application.config.load_database_yaml
        .dig('test', 'main')
        .slice('adapter', 'encoding', 'database', 'username', 'password', 'host')
        .symbolize_keys
    end

    let(:additional_database_config) do
      # Use built-in postgres database
      main_database_config.merge(database: 'postgres')
    end

    around do |example|
      with_reestablished_active_record_base(reconnect: true) do
        with_db_configs(test: test_config) do
          example.run
        end
      end
    end

    shared_examples 'validates successfully' do
      it 'by default' do
        expect { run_rake_task('gitlab:db:validate_config') }.not_to output(/Database config validation failure/).to_stderr
        expect { run_rake_task('gitlab:db:validate_config') }.not_to raise_error
      end

      it 'for production' do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

        expect { run_rake_task('gitlab:db:validate_config') }.not_to output(/Database config validation failure/).to_stderr
        expect { run_rake_task('gitlab:db:validate_config') }.not_to raise_error
      end

      it 'always re-establishes ActiveRecord::Base connection to main config' do
        run_rake_task('gitlab:db:validate_config')

        expect(ActiveRecord::Base.connection_db_config.configuration_hash).to include(main_database_config) # rubocop: disable Database/MultipleDatabases
      end

      it 'if GITLAB_VALIDATE_DATABASE_CONFIG is set' do
        stub_env('GITLAB_VALIDATE_DATABASE_CONFIG', '1')
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

        expect { run_rake_task('gitlab:db:validate_config') }.not_to output(/Database config validation failure/).to_stderr
        expect { run_rake_task('gitlab:db:validate_config') }.not_to raise_error
      end

      context 'when finding the initializer fails' do
        where(:raised_error) { [ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad] }
        with_them do
          it "does not raise an error for #{params[:raised_error]}" do
            allow(ActiveRecord::Base.connection).to receive(:select_one).and_raise(raised_error) # rubocop: disable Database/MultipleDatabases

            expect { run_rake_task('gitlab:db:validate_config') }.not_to output(/Database config validation failure/).to_stderr
            expect { run_rake_task('gitlab:db:validate_config') }.not_to raise_error
          end
        end
      end
    end

    shared_examples 'raises an error' do |match|
      it 'by default' do
        expect { run_rake_task('gitlab:db:validate_config') }.to raise_error(match)
      end

      it 'for production' do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

        expect { run_rake_task('gitlab:db:validate_config') }.to raise_error(match)
      end

      it 'always re-establishes ActiveRecord::Base connection to main config' do
        expect { run_rake_task('gitlab:db:validate_config') }.to raise_error(match)

        expect(ActiveRecord::Base.connection_db_config.configuration_hash).to include(main_database_config) # rubocop: disable Database/MultipleDatabases
      end

      it 'if GITLAB_VALIDATE_DATABASE_CONFIG=1' do
        stub_env('GITLAB_VALIDATE_DATABASE_CONFIG', '1')

        expect { run_rake_task('gitlab:db:validate_config') }.to raise_error(match)
      end

      it 'to stderr if GITLAB_VALIDATE_DATABASE_CONFIG=0' do
        stub_env('GITLAB_VALIDATE_DATABASE_CONFIG', '0')

        expect { run_rake_task('gitlab:db:validate_config') }.to output(match).to_stderr
      end
    end

    context 'when only main: is specified' do
      let(:test_config) do
        {
          main: main_database_config
        }
      end

      it_behaves_like 'validates successfully'

      context 'when config is pointing to incorrect server' do
        let(:test_config) do
          {
            main: main_database_config.merge(port: 11235)
          }
        end

        it_behaves_like 'validates successfully'
      end

      context 'when config is pointing to non-existent database' do
        let(:test_config) do
          {
            main: main_database_config.merge(database: 'non_existent_database')
          }
        end

        it_behaves_like 'validates successfully'
      end
    end

    context 'when main: uses database_tasks=false' do
      let(:test_config) do
        {
          main: main_database_config.merge(database_tasks: false)
        }
      end

      it_behaves_like 'raises an error', /The 'main' is required to use 'database_tasks: true'/
    end

    context 'when many configurations share the same database' do
      context 'when no database_tasks is specified, assumes true' do
        let(:test_config) do
          {
            main: main_database_config,
            ci: main_database_config
          }
        end

        it_behaves_like 'raises an error', /Many configurations \(main, ci\) share the same database/
      end

      context 'when database_tasks is specified' do
        let(:test_config) do
          {
            main: main_database_config.merge(database_tasks: true),
            ci: main_database_config.merge(database_tasks: true)
          }
        end

        it_behaves_like 'raises an error', /Many configurations \(main, ci\) share the same database/
      end

      context "when there's no main: but something different, as currently we only can share with main:" do
        let(:test_config) do
          {
            ci: main_database_config.merge(database_tasks: false)
          }
        end

        it_behaves_like 'raises an error', /The 'ci' is expecting to share configuration with 'main', but no such is to be found/
      end
    end

    context 'when ci: uses different database' do
      context 'and does not specify database_tasks which indicates using dedicated database' do
        let(:test_config) do
          {
            main: main_database_config,
            ci: additional_database_config
          }
        end

        it_behaves_like 'validates successfully'
      end

      context 'and does specify database_tasks=false which indicates sharing with main:' do
        let(:test_config) do
          {
            main: main_database_config,
            ci: additional_database_config.merge(database_tasks: false)
          }
        end

        it_behaves_like 'raises an error', /The 'ci' since it is using 'database_tasks: false' should share database with 'main:'/
      end
    end

    context 'one of the databases is in read-only mode' do
      let(:test_config) do
        {
          main: main_database_config
        }
      end

      let(:exception) { ActiveRecord::StatementInvalid.new("READONLY") }

      before do
        allow(exception).to receive(:cause).and_return(PG::ReadOnlySqlTransaction.new("cannot execute UPSERT in a read-only transaction"))

        unless Gitlab.next_rails?
          allow(ActiveRecord::InternalMetadata).to receive(:upsert).at_least(:once).and_raise(exception)
        end
      end

      it_behaves_like 'validates successfully'
    end
  end

  %w[db:migrate db:schema:load db:schema:dump].each do |task|
    context "when running #{task}" do
      it "does run gitlab:db:validate_config before" do
        expect(Rake::Task['gitlab:db:validate_config']).to receive(:execute).and_return(true)
        expect(Rake::Task[task]).to receive(:execute).and_return(true)

        Rake::Task['gitlab:db:validate_config'].reenable
        run_rake_task(task)
      end
    end
  end
end
