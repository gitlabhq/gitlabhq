# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:db:lock_writes', :silence_stdout, :reestablished_active_record_base, :delete,
               :suppress_gitlab_schemas_validate_connection, feature_category: :pods do
  before :all do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/db/validate_config'
    Rake.application.rake_require 'tasks/gitlab/db/lock_writes'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  let(:main_connection) { ApplicationRecord.connection }
  let(:ci_connection) { Ci::ApplicationRecord.connection }
  let!(:user) { create(:user) }
  let!(:ci_build) { create(:ci_build) }

  let(:detached_partition_table) { '_test_gitlab_main_part_20220101' }

  before do
    create_detached_partition_sql = <<~SQL
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic._test_gitlab_main_part_20220101 (
        id bigserial primary key not null
      )
    SQL

    main_connection.execute(create_detached_partition_sql)
    ci_connection.execute(create_detached_partition_sql)

    Gitlab::Database::SharedModel.using_connection(main_connection) do
      Postgresql::DetachedPartition.create!(
        table_name: detached_partition_table,
        drop_after: Time.current
      )
    end
  end

  after do
    run_rake_task('gitlab:db:unlock_writes')
  end

  after(:all) do
    drop_detached_partition_sql = <<~SQL
      DROP TABLE IF EXISTS gitlab_partitions_dynamic._test_gitlab_main_part_20220101
    SQL

    ApplicationRecord.connection.execute(drop_detached_partition_sql)
    Ci::ApplicationRecord.connection.execute(drop_detached_partition_sql)

    Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
      Postgresql::DetachedPartition.delete_all
    end
  end

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
          User.last.touch
          Ci::Build.last.touch
        end.not_to raise_error
      end
    end
  end

  context 'multiple databases' do
    before do
      skip_if_multiple_databases_not_setup

      Gitlab::Database::SharedModel.using_connection(ci_connection) do
        Postgresql::DetachedPartition.create!(
          table_name: detached_partition_table,
          drop_after: Time.current
        )
      end
    end

    context 'when locking writes' do
      it 'still allows writes on the tables with the correct connections' do
        User.update_all(updated_at: Time.now)
        Ci::Build.update_all(updated_at: Time.now)
      end

      it 'still allows writing to gitlab_shared schema on any connection' do
        connections = [main_connection, ci_connection]
        connections.each do |connection|
          Gitlab::Database::SharedModel.using_connection(connection) do
            LooseForeignKeys::DeletedRecord.create!(
              fully_qualified_table_name: "public.users",
              primary_key_value: 1,
              cleanup_attempts: 0
            )
          end
        end
      end

      it 'prevents writes on the main tables on the ci database' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          ci_connection.execute("delete from users")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "users" is write protected/)
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

      it 'prevents writes to detached partitions' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          ci_connection.execute("INSERT INTO gitlab_partitions_dynamic.#{detached_partition_table} DEFAULT VALUES")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "#{detached_partition_table}" is write protected/)
      end
    end

    context 'when running in dry_run mode' do
      before do
        stub_env('DRY_RUN', 'true')
      end

      it 'allows writes on the main tables on the ci database' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          ci_connection.execute("delete from users")
        end.not_to raise_error
      end

      it 'allows writes on the ci tables on the main database' do
        run_rake_task('gitlab:db:lock_writes')
        expect do
          main_connection.execute("delete from ci_builds")
        end.not_to raise_error
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

      it 'allows writes again to detached partitions' do
        run_rake_task('gitlab:db:unlock_writes')

        expect do
          ci_connection.execute("INSERT INTO gitlab_partitions_dynamic._test_gitlab_main_part_20220101 DEFAULT VALUES")
        end.not_to raise_error
      end
    end
  end

  def number_of_triggers(connection)
    connection.select_value("SELECT count(*) FROM information_schema.triggers")
  end
end
