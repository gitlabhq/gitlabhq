# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlDatabaseTasks::LoadSchemaVersionsMixin do
  let(:db_name) { 'primary' }

  let(:instance_class) do
    klass = Class.new do
      def structure_load
        original_structure_load
      end

      def original_structure_load
      end
    end

    klass.prepend(described_class)

    klass
  end

  let(:instance) { instance_class.new }

  before do
    # connection is available in ActiveRecord::Tasks::PostgreSQLDatabaseTasks
    allow(instance).to receive_message_chain(:connection, :pool, :db_config, :name).and_return(db_name)
  end

  context 'when database is primary' do
    it 'loads version files' do
      expect(Gitlab::Database::SchemaVersionFiles).to receive(:load_all)
      expect(instance).to receive(:original_structure_load)

      instance.structure_load
    end
  end

  context 'when the database is ci' do
    let(:db_name) { 'ci' }

    it 'does not load version files' do
      expect(Gitlab::Database::SchemaVersionFiles).not_to receive(:load_all)
      expect(instance).to receive(:original_structure_load)

      instance.structure_load
    end
  end
end
