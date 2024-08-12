# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::PgBackendPid, feature_category: :database do
  describe Gitlab::Database::Migrations::PgBackendPid::MigratorPgBackendPid do
    let(:block) { -> {} }

    let(:klass) do
      Class.new do
        def initialize(block)
          @block = block
        end

        def with_advisory_lock
          @block.call
        end

        def connection
          ApplicationRecord.connection
        end
      end
    end

    let(:patched_instance) { klass.prepend(described_class).new(block) }

    it 'wraps the method execution with calls to .say' do
      expect(Gitlab::Database::Migrations::PgBackendPid).to receive(:say).twice
      expect(block).to receive(:call)

      patched_instance.with_advisory_lock
    end

    context 'when an error is raised' do
      let(:block) { -> { raise ActiveRecord::ConcurrentMigrationError, 'test' } }

      it 'wraps the method execution with calls to .say' do
        expect(Gitlab::Database::Migrations::PgBackendPid).to receive(:say).twice

        expect do
          patched_instance.with_advisory_lock
        end.to raise_error ActiveRecord::ConcurrentMigrationError
      end
    end
  end

  describe Gitlab::Database::Migrations::PgBackendPid::OldMigratorPgBackendPid do
    let(:klass) do
      Class.new do
        def with_advisory_lock_connection
          yield :conn
        end
      end
    end

    it 're-yields with same arguments and wraps it with calls to .say' do
      patched_instance = klass.prepend(described_class).new
      expect(Gitlab::Database::Migrations::PgBackendPid).to receive(:say).twice

      expect { |b| patched_instance.with_advisory_lock_connection(&b) }.to yield_with_args(:conn)
    end

    it 're-yields with same arguments and wraps it with calls to .say even when error is raised' do
      patched_instance = klass.prepend(described_class).new
      expect(Gitlab::Database::Migrations::PgBackendPid).to receive(:say).twice

      expect do
        patched_instance.with_advisory_lock_connection do
          raise ActiveRecord::ConcurrentMigrationError, 'test'
        end
      end.to raise_error ActiveRecord::ConcurrentMigrationError
    end
  end

  describe '.patch!' do
    it 'patches ActiveRecord::Migrator' do
      if ::Gitlab.next_rails?
        expect(ActiveRecord::Migrator).to receive(:prepend).with(described_class::MigratorPgBackendPid)
      else
        expect(ActiveRecord::Migrator).to receive(:prepend).with(described_class::OldMigratorPgBackendPid)
      end

      described_class.patch!
    end
  end

  describe '.say' do
    let(:conn) { ActiveRecord::Base.connection }

    it 'outputs the connection information' do
      expect(conn).to receive(:object_id).and_return(9876)
      expect(conn).to receive(:select_value).with('SELECT pg_backend_pid()').and_return(12345)
      expect(Gitlab::Database).to receive(:db_config_name).with(conn).and_return('main')

      expected_output = "main: == [advisory_lock_connection] object_id: 9876, pg_backend_pid: 12345\n"

      expect { described_class.say(conn) }.to output(expected_output).to_stdout
    end

    it 'outputs nothing if ActiveRecord::Migration.verbose is false' do
      allow(ActiveRecord::Migration).to receive(:verbose).and_return(false)

      expect { described_class.say(conn) }.not_to output.to_stdout
    end
  end
end
