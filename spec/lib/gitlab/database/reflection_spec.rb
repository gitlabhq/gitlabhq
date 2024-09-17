# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reflection, feature_category: :database do
  let(:database) { described_class.new(ApplicationRecord) }

  describe '#username' do
    context 'when a username is set' do
      it 'returns the username' do
        allow(database).to receive(:config).and_return(username: 'bob')

        expect(database.username).to eq('bob')
      end
    end

    context 'when a username is not set' do
      it 'returns the value of the USER environment variable' do
        allow(database).to receive(:config).and_return(username: nil)
        stub_env('USER', 'bob')

        expect(database.username).to eq('bob')
      end
    end
  end

  describe '#database_name' do
    it 'returns the name of the database' do
      allow(database).to receive(:config).and_return(database: 'test')

      expect(database.database_name).to eq('test')
    end
  end

  describe '#adapter_name' do
    it 'returns the database adapter name' do
      allow(database).to receive(:config).and_return(adapter: 'test')

      expect(database.adapter_name).to eq('test')
    end
  end

  describe '#human_adapter_name' do
    context 'when the adapter is PostgreSQL' do
      it 'returns PostgreSQL' do
        allow(database).to receive(:config).and_return(adapter: 'postgresql')

        expect(database.human_adapter_name).to eq('PostgreSQL')
      end
    end

    context 'when the adapter is not PostgreSQL' do
      it 'returns Unknown' do
        allow(database).to receive(:config).and_return(adapter: 'kittens')

        expect(database.human_adapter_name).to eq('Unknown')
      end
    end
  end

  describe '#postgresql?' do
    context 'when using PostgreSQL' do
      it 'returns true' do
        allow(database).to receive(:adapter_name).and_return('PostgreSQL')

        expect(database.postgresql?).to eq(true)
      end
    end

    context 'when not using PostgreSQL' do
      it 'returns false' do
        allow(database).to receive(:adapter_name).and_return('MySQL')

        expect(database.postgresql?).to eq(false)
      end
    end
  end

  describe '#db_read_only?' do
    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "t" }])

      expect(database.db_read_only?).to be_truthy
    end

    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => true }])

      expect(database.db_read_only?).to be_truthy
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "f" }])

      expect(database.db_read_only?).to be_falsey
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => false }])

      expect(database.db_read_only?).to be_falsey
    end
  end

  describe '#db_read_write?' do
    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "t" }])

      expect(database.db_read_write?).to eq(false)
    end

    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => true }])

      expect(database.db_read_write?).to eq(false)
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "f" }])

      expect(database.db_read_write?).to eq(true)
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => false }])

      expect(database.db_read_write?).to eq(true)
    end
  end

  describe '#version' do
    around do |example|
      database.instance_variable_set(:@version, nil)
      example.run
      database.instance_variable_set(:@version, nil)
    end

    context "on postgresql" do
      it "extracts the version number" do
        allow(database)
          .to receive(:database_version)
          .and_return("PostgreSQL 9.4.4 on x86_64-apple-darwin14.3.0")

        expect(database.version).to eq '9.4.4'
      end
    end

    it 'memoizes the result' do
      count = ActiveRecord::QueryRecorder
        .new { 2.times { database.version } }
        .count

      expect(count).to eq(1)
    end
  end

  describe '#postgresql_minimum_supported_version?' do
    it 'returns false when using PostgreSQL 12' do
      allow(database).to receive(:version).and_return('12')

      expect(database.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns falses when using PostgreSQL 13' do
      allow(database).to receive(:version).and_return('13')

      expect(database.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns true when using PostgreSQL 14' do
      allow(database).to receive(:version).and_return('14')

      expect(database.postgresql_minimum_supported_version?).to eq(true)
    end

    it 'returns true when using PostgreSQL 15' do
      allow(database).to receive(:version).and_return('15')

      expect(database.postgresql_minimum_supported_version?).to eq(true)
    end

    it 'returns true when using PostgreSQL 16' do
      allow(database).to receive(:version).and_return('16')

      expect(database.postgresql_minimum_supported_version?).to eq(true)
    end
  end

  describe '#cached_column_exists?' do
    it 'only retrieves the data from the schema cache' do
      database = described_class.new(Project)
      queries = ActiveRecord::QueryRecorder.new do
        2.times do
          expect(database.cached_column_exists?(:id)).to be_truthy
          expect(database.cached_column_exists?(:bogus_column)).to be_falsey
        end
      end

      expect(queries.count).to eq(0)
    end
  end

  describe '#cached_table_exists?' do
    it 'only retrieves the data from the schema cache' do
      dummy = Class.new(ActiveRecord::Base) do
        self.table_name = 'bogus_table_name'
      end

      queries = ActiveRecord::QueryRecorder.new do
        2.times do
          expect(described_class.new(Project).cached_table_exists?).to be_truthy
          expect(described_class.new(dummy).cached_table_exists?).to be_falsey
        end
      end

      expect(queries.count).to eq(0)
    end

    it 'returns false when database does not exist' do
      database = described_class.new(Project)

      expect(database.model).to receive(:connection) do
        raise ActiveRecord::NoDatabaseError, 'broken'
      end

      expect(database.cached_table_exists?).to be(false)
    end
  end

  describe '#exists?' do
    it 'returns true if the database exists' do
      expect(database.exists?).to be(true)
    end

    it "returns false if the database doesn't exist" do
      expect(database.model.connection.schema_cache)
        .to receive(:database_version)
        .and_raise(ActiveRecord::NoDatabaseError)

      expect(database.exists?).to be(false)
    end
  end

  describe '#system_id' do
    it 'returns the PostgreSQL system identifier' do
      expect(database.system_id).to be_an_instance_of(Integer)
    end
  end

  describe '#flavor', :delete do
    let(:result) { [double] }
    let(:connection) { database.model.connection }

    def stub_statements(statements)
      statements = Array.wrap(statements)
      execute = connection.method(:execute)

      allow(connection).to receive(:execute) do |arg|
        if statements.include?(arg)
          result
        else
          execute.call(arg)
        end
      end
    end

    it 're-raises exceptions not matching expected messages' do
      expect(database.model.connection)
        .to receive(:execute)
        .and_raise(ActiveRecord::StatementInvalid, 'Something else')

      expect { database.flavor }.to raise_error ActiveRecord::StatementInvalid, /Something else/
    end

    it 'recognizes Amazon Aurora PostgreSQL' do
      stub_statements(['SHOW rds.extensions', 'SELECT AURORA_VERSION()'])

      expect(database.flavor).to eq('Amazon Aurora PostgreSQL')
    end

    it 'recognizes PostgreSQL on Amazon RDS' do
      stub_statements('SHOW rds.extensions')

      expect(database.flavor).to eq('PostgreSQL on Amazon RDS')
    end

    it 'recognizes CloudSQL for PostgreSQL' do
      stub_statements('SHOW cloudsql.iam_authentication')

      expect(database.flavor).to eq('Cloud SQL for PostgreSQL')
    end

    it 'recognizes Azure Database for PostgreSQL - Flexible Server' do
      stub_statements(["SELECT datname FROM pg_database WHERE datname = 'azure_maintenance'", 'SHOW azure.extensions'])

      expect(database.flavor).to eq('Azure Database for PostgreSQL - Flexible Server')
    end

    it 'recognizes Azure Database for PostgreSQL - Single Server' do
      stub_statements("SELECT datname FROM pg_database WHERE datname = 'azure_maintenance'")

      expect(database.flavor).to eq('Azure Database for PostgreSQL - Single Server')
    end

    it 'recognizes AlloyDB for PostgreSQL' do
      stub_statements("SELECT name FROM pg_settings WHERE name LIKE 'alloydb%'")

      expect(database.flavor).to eq('AlloyDB for PostgreSQL')
    end

    it 'returns nil if can not recognize the flavor' do
      expect(database.flavor).to be_nil
    end
  end

  describe '#config' do
    it 'returns a HashWithIndifferentAccess' do
      expect(database.config)
        .to be_an_instance_of(HashWithIndifferentAccess)
    end

    it 'returns a default pool size', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/467632' do
      expect(database.config)
        .to include(pool: Gitlab::Database.default_pool_size)
    end

    it 'does not cache its results' do
      a = database.config
      b = database.config

      expect(a).not_to equal(b)
    end
  end
end
