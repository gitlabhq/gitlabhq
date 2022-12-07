# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlAdapter::DumpSchemaVersionsMixin do
  let(:instance_class) do
    klass = Class.new do
      def dump_schema_information
        original_dump_schema_information
      end

      def original_dump_schema_information; end
    end

    klass.prepend(described_class)

    klass
  end

  let(:instance) { instance_class.new }

  it 'calls SchemaMigrations touch_all and skips original implementation' do
    expect(Gitlab::Database::SchemaMigrations).to receive(:touch_all).with(instance)
    expect(instance).not_to receive(:original_dump_schema_information)

    instance.dump_schema_information
  end

  it 'does not call touch_all in production' do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

    expect(Gitlab::Database::SchemaMigrations).not_to receive(:touch_all)

    instance.dump_schema_information
  end
end
