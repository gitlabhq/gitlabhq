# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TablesLocker, :reestablished_active_record_base, :delete, :silence_stdout,
               :suppress_gitlab_schemas_validate_connection, feature_category: :pods do
  let(:main_connection) { ApplicationRecord.connection }
  let(:ci_connection) { Ci::ApplicationRecord.connection }
  let!(:user) { create(:user) }
  let!(:ci_build) { create(:ci_build) }

  let(:detached_partition_table) { '_test_gitlab_main_part_20220101' }

  before do
    described_class.new.unlock_writes
  end

  before(:all) do
    create_detached_partition_sql = <<~SQL
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic._test_gitlab_main_part_20220101 (
        id bigserial primary key not null
      )
    SQL

    ApplicationRecord.connection.execute(create_detached_partition_sql)
    Ci::ApplicationRecord.connection.execute(create_detached_partition_sql)

    Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
      Postgresql::DetachedPartition.create!(
        table_name: '_test_gitlab_main_part_20220101',
        drop_after: Time.current
      )
    end
  end

  after(:all) do
    described_class.new.unlock_writes

    drop_detached_partition_sql = <<~SQL
      DROP TABLE IF EXISTS gitlab_partitions_dynamic._test_gitlab_main_part_20220101
    SQL

    ApplicationRecord.connection.execute(drop_detached_partition_sql)
    Ci::ApplicationRecord.connection.execute(drop_detached_partition_sql)

    Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
      Postgresql::DetachedPartition.delete_all
    end
  end

  context 'when running on single database' do
    before do
      skip_if_multiple_databases_are_setup
    end

    describe '#lock_writes' do
      subject { described_class.new.lock_writes }

      it 'does not add any triggers to the main schema tables' do
        expect { subject }.not_to change { number_of_triggers(main_connection) }
      end

      it 'will be still able to modify tables that belong to the main two schemas' do
        subject

        expect do
          User.last.touch
          Ci::Build.last.touch
        end.not_to raise_error
      end
    end
  end

  context 'when running on multiple databases' do
    before do
      skip_if_multiple_databases_not_setup

      Gitlab::Database::SharedModel.using_connection(ci_connection) do
        Postgresql::DetachedPartition.create!(
          table_name: detached_partition_table,
          drop_after: Time.zone.now
        )
      end
    end

    describe '#lock_writes' do
      subject { described_class.new.lock_writes }

      it 'still allows writes on the tables with the correct connections' do
        User.touch_all
        Ci::Build.touch_all
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
        subject

        expect do
          ci_connection.execute("delete from users")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "users" is write protected/)
      end

      it 'prevents writes on the ci tables on the main database' do
        subject

        expect do
          main_connection.execute("delete from ci_builds")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "ci_builds" is write protected/)
      end

      it 'prevents truncating a ci table on the main database' do
        subject

        expect do
          main_connection.execute("truncate ci_build_needs")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "ci_build_needs" is write protected/)
      end

      it 'prevents writes to detached partitions' do
        subject

        expect do
          ci_connection.execute("INSERT INTO gitlab_partitions_dynamic.#{detached_partition_table} DEFAULT VALUES")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "#{detached_partition_table}" is write protected/)
      end

      context 'when running in dry_run mode' do
        subject { described_class.new(dry_run: true).lock_writes }

        it 'allows writes on the main tables on the ci database' do
          subject

          expect do
            ci_connection.execute("delete from users")
          end.not_to raise_error
        end

        it 'allows writes on the ci tables on the main database' do
          subject

          expect do
            main_connection.execute("delete from ci_builds")
          end.not_to raise_error
        end
      end

      context 'when running on multiple shared databases' do
        before do
          allow(::Gitlab::Database).to receive(:db_config_share_with).and_return(nil)
          ci_db_config = Ci::ApplicationRecord.connection_db_config
          allow(::Gitlab::Database).to receive(:db_config_share_with).with(ci_db_config).and_return('main')
        end

        it 'does not lock any tables if the ci database is shared with main database' do
          subject { described_class.new.lock_writes }

          expect do
            ApplicationRecord.connection.execute("delete from ci_builds")
            Ci::ApplicationRecord.connection.execute("delete from users")
          end.not_to raise_error
        end
      end
    end
  end

  context 'when geo database is configured' do
    let(:lock_writes_manager) do
      instance_double(Gitlab::Database::LockWritesManager, lock_writes: nil, unlock_writes: nil)
    end

    let(:geo_table) do
      Gitlab::Database::GitlabSchema
        .tables_to_schema.filter_map { |table_name, schema| table_name if schema == :gitlab_geo }
        .first
    end

    subject { described_class.new.unlock_writes }

    before do
      skip "Geo database is not configured" unless Gitlab::Database.has_config?(:geo)

      allow(Gitlab::Database::LockWritesManager).to receive(:new).with(any_args).and_return(lock_writes_manager)
    end

    it 'does not lock table in geo database' do
      expect(Gitlab::Database::LockWritesManager).not_to receive(:new).with(
        table_name: geo_table,
        connection: anything,
        database_name: 'geo',
        with_retries: true,
        logger: anything,
        dry_run: anything
      )

      subject
    end
  end
end

def number_of_triggers(connection)
  connection.select_value("SELECT count(*) FROM information_schema.triggers")
end
