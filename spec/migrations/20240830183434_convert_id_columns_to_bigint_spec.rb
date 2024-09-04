# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ConvertIdColumnsToBigint, feature_category: :database, schema: 20240830183434 do
  let(:migration) { described_class.new }
  let(:test_table_name) { '_test_table' }
  let(:connection) { ActiveRecord::Base.connection }

  describe '#up' do
    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{test_table_name} (
          id bigserial not null,
          copy_id integer,
          reference_ids integer[] DEFAULT '{}'::integer[]
        );
      SQL
    end

    after do
      connection.execute("DROP TABLE #{test_table_name}")
    end

    context 'on Gitlab.com' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      end

      it 'does nothing' do
        expect(migration).not_to receive(:convert_column)

        migration.up
      end
    end

    context 'on test or dev environment' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
      end

      it_behaves_like 'All IDs are bigint', from_migration: true

      it 'changes default value to bigint' do
        migration.up

        result = connection.execute(<<~SQL)
          SELECT column_default FROM information_schema.columns
          WHERE table_name = '#{test_table_name}' AND column_name = 'reference_ids'
        SQL

        expect(result.first['column_default']).to eq("'{}'::bigint[]")
      end
    end
  end
end
