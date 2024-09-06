# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::LockRetryMixin, feature_category: :database do
  describe Gitlab::Database::Migrations::LockRetryMixin::ActiveRecordMigrationProxyLockRetries do
    let(:connection) { ActiveRecord::Base.connection }
    let(:migration) { double(connection: connection) }
    let(:return_value) { double }
    let(:class_def) do
      Class.new do
        include Gitlab::Database::Migrations::LockRetryMixin::ActiveRecordMigrationProxyLockRetries

        attr_reader :migration

        def initialize(migration)
          @migration = migration
        end
      end
    end

    shared_examples 'delegable' do |method|
      subject { class_def.new(migration).public_send(method) }

      it 'delegates to migration' do
        expect(migration).to receive(method).and_return(return_value)

        expect(subject).to eq(return_value)
      end
    end

    describe '#enable_lock_retries?' do
      it_behaves_like 'delegable', :enable_lock_retries?
    end

    describe '#with_lock_retries_used!' do
      it_behaves_like 'delegable', :with_lock_retries_used!
    end

    describe '#with_lock_retries_used?' do
      it_behaves_like 'delegable', :with_lock_retries_used?
    end

    describe '#migration_class' do
      subject { class_def.new(migration).migration_class }

      it 'retrieves actual migration class from #migration' do
        expect(migration).to receive(:class).and_return(return_value)

        result = subject

        expect(result).to eq(return_value)
      end
    end

    describe '#migration_connection' do
      subject { class_def.new(migration).migration_connection }

      it 'retrieves actual migration connection from #migration' do
        expect(migration).to receive(:connection).and_return(return_value)

        result = subject

        expect(result).to eq(return_value)
      end
    end
  end

  describe Gitlab::Database::Migrations::LockRetryMixin::ActiveRecordMigratorLockRetries do
    let(:class_def) do
      Class.new do
        attr_reader :receiver

        def initialize(receiver)
          @receiver = receiver
        end

        def ddl_transaction(migration, &block)
          receiver.ddl_transaction(migration, &block)
        end

        def use_transaction?(migration)
          receiver.use_transaction?(migration)
        end
      end.prepend(described_class)
    end

    subject { class_def.new(receiver) }

    before do
      allow(migration).to receive(:migration_class).and_return('TestClass')
      allow(receiver).to receive(:ddl_transaction)
    end

    context 'with transactions disabled' do
      let(:migration) { double('migration') }
      let(:receiver) { double('receiver', use_transaction?: false) }

      it 'calls super method' do
        p = proc {}

        expect(receiver).to receive(:ddl_transaction).with(migration, &p)

        subject.ddl_transaction(migration, &p)
      end
    end

    context 'with transactions enabled' do
      before do
        allow(migration).to receive(:migration_connection).and_return(connection)
      end

      let(:receiver) { double('receiver', use_transaction?: true) }

      let(:migration) do
        Class.new(Gitlab::Database::Migration[2.2]) do
          milestone '16.10'

          @_defining_file = 'db/migrate/1_test.rb'

          def change
            # no-op
          end
        end.new
      end

      let(:connection) { ActiveRecord::Base.connection }

      it 'calls super method and sets with_lock_retries_used! on the migration' do
        p = proc {}

        expect(receiver).not_to receive(:ddl_transaction)

        expect_next_instance_of(Gitlab::Database::WithLockRetries) do |retries|
          expect(retries).to receive(:run).with(raise_on_exhaustion: true, &p)
        end

        subject.ddl_transaction(migration, &p)

        expect(migration.with_lock_retries_used?).to be_truthy
      end
    end
  end

  describe '.patch!' do
    subject { described_class.patch! }

    it 'patches MigrationProxy' do
      expect(ActiveRecord::MigrationProxy).to receive(:prepend).with(Gitlab::Database::Migrations::LockRetryMixin::ActiveRecordMigrationProxyLockRetries)

      subject
    end

    it 'patches Migrator' do
      expect(ActiveRecord::Migrator).to receive(:prepend).with(Gitlab::Database::Migrations::LockRetryMixin::ActiveRecordMigratorLockRetries)

      subject
    end
  end
end
