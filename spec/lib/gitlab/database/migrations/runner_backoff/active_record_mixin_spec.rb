# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::RunnerBackoff::ActiveRecordMixin, feature_category: :database do
  let(:migration_class) { Gitlab::Database::Migration[2.1] }

  describe described_class::ActiveRecordMigrationProxyRunnerBackoff do
    let(:migration) { instance_double(migration_class) }

    let(:class_def) do
      Class.new do
        attr_reader :migration

        def initialize(migration)
          @migration = migration
        end
      end.prepend(described_class)
    end

    describe '#enable_runner_backoff?' do
      subject { class_def.new(migration).enable_runner_backoff? }

      it 'delegates to #migration' do
        expect(migration).to receive(:enable_runner_backoff?).and_return(true)

        expect(subject).to eq(true)
      end

      it 'returns false if migration does not implement it' do
        expect(migration).to receive(:respond_to?).with(:enable_runner_backoff?).and_return(false)

        expect(subject).to eq(false)
      end
    end
  end

  describe described_class::ActiveRecordMigratorRunnerBackoff do
    let(:class_def) do
      Class.new do
        attr_reader :receiver

        def initialize(receiver)
          @receiver = receiver
        end

        def execute_migration_in_transaction(migration)
          receiver.execute_migration_in_transaction(migration)
        end
      end.prepend(described_class)
    end

    let(:receiver) { instance_double(ActiveRecord::Migrator, 'receiver') }

    subject { class_def.new(receiver) }

    before do
      allow(migration).to receive(:name).and_return('TestClass')
      allow(receiver).to receive(:execute_migration_in_transaction)
    end

    context 'with runner backoff disabled' do
      let(:migration) { instance_double(migration_class, enable_runner_backoff?: false) }

      it 'calls super method' do
        expect(receiver).to receive(:execute_migration_in_transaction).with(migration)

        subject.execute_migration_in_transaction(migration)
      end
    end

    context 'with runner backoff enabled' do
      let(:migration) { instance_double(migration_class, enable_runner_backoff?: true) }

      it 'calls super method' do
        expect(Gitlab::Database::Migrations::RunnerBackoff::Communicator)
          .to receive(:execute_with_lock).with(migration).and_call_original

        expect(receiver).to receive(:execute_migration_in_transaction)
          .with(migration)

        subject.execute_migration_in_transaction(migration)
      end
    end
  end

  describe '.patch!' do
    subject { described_class.patch! }

    it 'patches MigrationProxy' do
      expect(ActiveRecord::MigrationProxy)
        .to receive(:prepend)
        .with(described_class::ActiveRecordMigrationProxyRunnerBackoff)

      subject
    end

    it 'patches Migrator' do
      expect(ActiveRecord::Migrator)
        .to receive(:prepend)
        .with(described_class::ActiveRecordMigratorRunnerBackoff)

      subject
    end
  end
end
