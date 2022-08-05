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

      it 'allows writes again on the gitlab_ci tables on the main database' do
        run_rake_task('gitlab:db:unlock_writes')

        expect do
          main_connection.execute("delete from ci_builds")
        end.not_to raise_error
      end
    end
  end

  def number_of_triggers(connection)
    connection.select_value("SELECT count(*) FROM information_schema.triggers")
  end
end
