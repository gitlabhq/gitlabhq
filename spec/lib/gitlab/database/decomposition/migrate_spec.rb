# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Decomposition::Migrate, :delete, query_analyzers: false, feature_category: :cell do
  let(:ci_database_name) do
    config = ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash

    "#{config[:database]}_ci"
  end

  let(:ci_connection) do
    database_model = self.class.const_set(:TestCiApplicationRecord, Class.new(ApplicationRecord))

    database_model.establish_connection(
      ActiveRecord::DatabaseConfigurations::HashConfig.new(
        ActiveRecord::Base.connection_db_config.env_name,
        'ci',
        ActiveRecord::Base.connection_db_config.configuration_hash.dup.merge(database: ci_database_name)
      )
    )

    Gitlab::Database::LoadBalancing::Setup.new(database_model).setup

    database_model.connection
  end

  let(:backup_location_postfix) { SecureRandom.alphanumeric(10) }

  before do
    skip_if_database_exists(:ci)

    allow(SecureRandom).to receive(:alphanumeric).with(10).and_return(backup_location_postfix)
  end

  after do
    Milestone.delete_all
    Ci::Pipeline.delete_all
  end

  describe '#new' do
    context 'when backup_location is not specified' do
      subject(:instance) { described_class.new }

      it 'defaults to subdirectory of configured backup location' do
        expect(instance.instance_variable_get(:@backup_location)).to eq(
          File.join(Gitlab.config.backup.path, "migration_#{backup_location_postfix}")
        )
      end
    end

    context 'when backup_location is specified' do
      let(:backup_base_location) { Rails.root.join('tmp') }

      subject(:instance) { described_class.new(backup_base_location: backup_base_location) }

      it 'uses subdirectory of specified backup_location' do
        expect(instance.instance_variable_get(:@backup_location)).to eq(
          File.join(backup_base_location, "migration_#{backup_location_postfix}")
        )
      end

      context 'when specified_backup_location does not exist' do
        let(:backup_base_location) { Rails.root.join('tmp', SecureRandom.alphanumeric(10)) }

        context 'and creation of the directory succeeds' do
          it 'uses subdirectory of specified backup_location' do
            expect(instance.instance_variable_get(:@backup_location)).to eq(
              File.join(backup_base_location, "migration_#{backup_location_postfix}")
            )
          end
        end

        context 'and creation of the directory fails' do
          before do
            allow(FileUtils).to receive(:mkdir_p).with(backup_base_location).and_raise(Errno::EROFS.new)
          end

          it 'raises error' do
            expect { instance.process! }.to raise_error(
              Gitlab::Database::Decomposition::MigrateError,
              "Failed to create directory #{backup_base_location}: Read-only file system"
            )
          end
        end
      end
    end
  end

  describe '#process!' do
    subject(:process) { described_class.new.process! }

    before do
      # Database `ci` is not configured. But it can still exist. So drop and create it
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{ci_database_name} WITH (FORCE)")
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{ci_database_name}")
    end

    context 'when the checks pass' do
      let!(:milestone) { create(:milestone) }
      let!(:ci_pipeline) { create(:ci_pipeline) }

      it 'copies main database to ci database' do
        process

        ci_milestones = ci_connection.execute("SELECT COUNT(*) FROM milestones").getvalue(0, 0)
        ci_pipelines = ci_connection.execute("SELECT COUNT(*) FROM ci_pipelines").getvalue(0, 0)

        expect(ci_milestones).to be(Milestone.count)
        expect(ci_pipelines).to be(Ci::Pipeline.count)
      end
    end

    context 'when local diskspace is not enough' do
      let(:backup_location) { described_class.new.backup_location }
      let(:fake_stats) { instance_double(Sys::Filesystem::Stat, bytes_free: 1000) }

      before do
        allow(Sys::Filesystem).to receive(:stat).with(File.expand_path("#{backup_location}/../")).and_return(fake_stats)
      end

      it 'raises error' do
        expect { process }.to raise_error(
          Gitlab::Database::Decomposition::MigrateError,
          /Not enough diskspace available on #{backup_location}: Available: (.+?), Needed: (.+?)/
        )
      end
    end

    context 'when connection to ci database fails' do
      before do
        ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{ci_database_name} WITH (FORCE)")
      end

      it 'raises error' do
        host = ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash[:host]
        expect { process }.to raise_error(
          Gitlab::Database::Decomposition::MigrateError,
          "Can't connect to database '#{ci_database_name} on host '#{host}'. Ensure the database has been created.")
      end
    end

    context 'when ci database is not empty' do
      before do
        ci_connection.execute("CREATE TABLE IF NOT EXISTS _test_table (id integer, primary key (id))")
      end

      it 'raises error' do
        expect { process }.to raise_error(
          Gitlab::Database::Decomposition::MigrateError,
          "Database '#{ci_database_name}' is not empty"
        )
      end
    end

    context 'when already on decomposed setup' do
      before do
        allow(Gitlab::Database).to receive(:database_mode).and_return(Gitlab::Database::MODE_MULTIPLE_DATABASES)
      end

      it 'raises error' do
        expect { process }.to raise_error(
          Gitlab::Database::Decomposition::MigrateError,
          "GitLab is already configured to run on multiple databases"
        )
      end
    end

    context 'when not all background migrations are finished' do
      let!(:batched_migration) { create(:batched_background_migration, :active) }

      it 'raises error' do
        expect { process }.to raise_error(
          Gitlab::Database::Decomposition::MigrateError,
          "Found 1 unfinished background migration(s). Please wait until they are finished."
        )
      end
    end

    context 'when all background migrations are finished' do
      let!(:batched_migration_1) { create(:batched_background_migration, :finished) }
      let!(:batched_migration_2) { create(:batched_background_migration, :finalized) }

      it 'does not raise an error' do
        expect { process }.not_to raise_error
      end
    end
  end
end
