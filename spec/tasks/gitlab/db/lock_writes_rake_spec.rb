# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:db:lock_writes', :silence_stdout, :reestablished_active_record_base,
               :suppress_gitlab_schemas_validate_connection do
  before :all do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/db/validate_config'
    Rake.application.rake_require 'tasks/gitlab/db/lock_writes'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  let!(:project) { create(:project) }
  let!(:ci_build) { create(:ci_build) }
  let(:main_connection) { ApplicationRecord.connection }
  let(:ci_connection) { Ci::ApplicationRecord.connection }

  context 'single database' do
    before do
      skip_if_multiple_databases_are_setup
    end

    context 'when locking writes' do
      it 'does not add any triggers to the main schema tables' do
        expect do
          run_rake_task('gitlab:db:lock_writes')
        end.to change {
          number_of_triggers(main_connection)
        }.by(0)
      end

      it 'will be still able to modify tables that belong to the main two schemas' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          Project.last.touch
          Ci::Build.last.touch
        end.not_to raise_error
      end
    end
  end

  context 'multiple databases' do
    before do
      skip_if_multiple_databases_not_setup
    end

    context 'when locking writes' do
      it 'adds 3 triggers to the ci schema tables on the main database' do
        expect do
          run_rake_task('gitlab:db:lock_writes')
        end.to change {
          number_of_triggers_on(main_connection, Ci::Build.table_name)
        }.by(3) # Triggers to block INSERT / UPDATE / DELETE
        # Triggers on TRUNCATE are not added to the information_schema.triggers
        # See https://www.postgresql.org/message-id/16934.1568989957%40sss.pgh.pa.us
      end

      it 'adds 3 triggers to the main schema tables on the ci database' do
        expect do
          run_rake_task('gitlab:db:lock_writes')
        end.to change {
          number_of_triggers_on(ci_connection, Project.table_name)
        }.by(3) # Triggers to block INSERT / UPDATE / DELETE
        # Triggers on TRUNCATE are not added to the information_schema.triggers
        # See https://www.postgresql.org/message-id/16934.1568989957%40sss.pgh.pa.us
      end

      it 'still allows writes on the tables with the correct connections' do
        Project.update_all(updated_at: Time.now)
        Ci::Build.update_all(updated_at: Time.now)
      end

      it 'still allows writing to gitlab_shared schema on any connection' do
        connections = [main_connection, ci_connection]
        connections.each do |connection|
          Gitlab::Database::SharedModel.using_connection(connection) do
            LooseForeignKeys::DeletedRecord.create!(
              fully_qualified_table_name: "public.projects",
              primary_key_value: 1,
              cleanup_attempts: 0
            )
          end
        end
      end

      it 'prevents writes on the main tables on the ci database' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          ci_connection.execute("delete from projects")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "projects" is write protected/)
      end

      it 'prevents writes on the ci tables on the main database' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          main_connection.execute("delete from ci_builds")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "ci_builds" is write protected/)
      end

      it 'prevents truncating a ci table on the main database' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          main_connection.execute("truncate ci_build_needs")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "ci_build_needs" is write protected/)
      end

      it 'retries again if it receives a statement_timeout a few number of times' do
        error_message = "PG::QueryCanceled: ERROR: canceling statement due to statement timeout"
        call_count = 0
        allow(main_connection).to receive(:execute) do |statement|
          if statement.include?("CREATE TRIGGER")
            call_count += 1
            raise(ActiveRecord::QueryCanceled, error_message) if call_count.even?
          end
        end
        run_rake_task('gitlab:db:lock_writes')
      end

      it 'raises the exception if it happened many times' do
        error_message = "PG::QueryCanceled: ERROR: canceling statement due to statement timeout"
        allow(main_connection).to receive(:execute) do |statement|
          if statement.include?("CREATE TRIGGER")
            raise(ActiveRecord::QueryCanceled, error_message)
          end
        end

        expect do
          run_rake_task('gitlab:db:lock_writes')
        end.to raise_error(ActiveRecord::QueryCanceled)
      end
    end

    context 'multiple shared databases' do
      before do
        allow(::Gitlab::Database).to receive(:db_config_share_with).and_return(nil)
        ci_db_config = Ci::ApplicationRecord.connection_db_config
        allow(::Gitlab::Database).to receive(:db_config_share_with).with(ci_db_config).and_return('main')
      end

      it 'does not lock any tables if the ci database is shared with main database' do
        run_rake_task('gitlab:db:lock_writes')

        expect do
          ApplicationRecord.connection.execute("delete from ci_builds")
          Ci::ApplicationRecord.connection.execute("delete from users")
        end.not_to raise_error
      end
    end

    context 'when unlocking writes' do
      before do
        run_rake_task('gitlab:db:lock_writes')
      end

      it 'removes the write protection triggers from the gitlab_main tables on the ci database' do
        expect do
          run_rake_task('gitlab:db:unlock_writes')
        end.to change {
          number_of_triggers_on(ci_connection, Project.table_name)
        }.by(-3) # Triggers to block INSERT / UPDATE / DELETE
        # Triggers on TRUNCATE are not added to the information_schema.triggers
        # See https://www.postgresql.org/message-id/16934.1568989957%40sss.pgh.pa.us

        expect do
          ci_connection.execute("delete from projects")
        end.not_to raise_error
      end

      it 'removes the write protection triggers from the gitlab_ci tables on the main database' do
        expect do
          run_rake_task('gitlab:db:unlock_writes')
        end.to change {
          number_of_triggers_on(main_connection, Ci::Build.table_name)
        }.by(-3)

        expect do
          main_connection.execute("delete from ci_builds")
        end.not_to raise_error
      end
    end
  end

  def number_of_triggers(connection)
    connection.select_value("SELECT count(*) FROM information_schema.triggers")
  end

  def number_of_triggers_on(connection, table_name)
    connection
      .select_value("SELECT count(*) FROM information_schema.triggers WHERE event_object_table=$1", nil, [table_name])
  end
end
