# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlDatabaseTasks::LoadSchemaVersionsMixin do
  let(:instance_class) do
    klass = Class.new do
      def structure_load
        original_structure_load
      end

      def original_structure_load; end
    end

    klass.prepend(described_class)

    klass
  end

  let(:instance) { instance_class.new }

  it 'calls SchemaMigrations load_all' do
    connection = double('connection')
    allow(instance).to receive(:connection).and_return(connection)

    expect(instance).to receive(:original_structure_load).ordered
    expect(Gitlab::Database::SchemaMigrations).to receive(:load_all).with(connection).ordered

    instance.structure_load
  end
end
