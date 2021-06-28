# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlAdapter::DumpSchemaVersionsMixin do
  let(:schema_migration) { double('schema_migration', all_versions: versions) }
  let(:db_name) { 'primary' }
  let(:versions) { %w(5 2 1000 200 4 93 2) }

  let(:instance_class) do
    klass = Class.new do
      def dump_schema_information
        original_dump_schema_information
      end

      def original_dump_schema_information
      end
    end

    klass.prepend(described_class)

    klass
  end

  let(:instance) { instance_class.new }

  before do
    allow(instance).to receive(:schema_migration).and_return(schema_migration)

    # pool is from ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    allow(instance).to receive_message_chain(:pool, :db_config, :name).and_return(db_name)
  end

  context 'when database name is primary' do
    context 'when version files exist' do
      it 'touches version files' do
        expect(Gitlab::Database::SchemaVersionFiles).to receive(:touch_all).with(versions)
        expect(instance).not_to receive(:original_dump_schema_information)

        instance.dump_schema_information
      end
    end

    context 'when version files do not exist' do
      let(:versions) { [] }

      it 'does not touch version files' do
        expect(Gitlab::Database::SchemaVersionFiles).not_to receive(:touch_all)
        expect(instance).not_to receive(:original_dump_schema_information)

        instance.dump_schema_information
      end
    end
  end

  context 'when database name is ci' do
    let(:db_name) { 'ci' }

    it 'does not touch version files' do
      expect(Gitlab::Database::SchemaVersionFiles).not_to receive(:touch_all)
      expect(instance).to receive(:original_dump_schema_information)

      instance.dump_schema_information
    end
  end
end
