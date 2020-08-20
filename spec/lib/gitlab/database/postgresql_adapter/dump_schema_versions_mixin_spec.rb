# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlAdapter::DumpSchemaVersionsMixin do
  let(:schema_migration) { double('schema_migration', all_versions: versions) }

  let(:instance) do
    Object.new.extend(described_class)
  end

  before do
    allow(instance).to receive(:schema_migration).and_return(schema_migration)
  end

  context 'when version files exist' do
    let(:versions) { %w(5 2 1000 200 4 93 2) }

    it 'touches version files' do
      expect(Gitlab::Database::SchemaVersionFiles).to receive(:touch_all).with(versions)

      instance.dump_schema_information
    end
  end

  context 'when version files do not exist' do
    let(:versions) { [] }

    it 'does not touch version files' do
      expect(Gitlab::Database::SchemaVersionFiles).not_to receive(:touch_all)

      instance.dump_schema_information
    end
  end
end
