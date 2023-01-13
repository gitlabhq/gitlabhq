# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafelyChangeColumnDefault, feature_category: :database do
  include Gitlab::Database::DynamicModelHelpers
  before do
    ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE _test_gitlab_main_data(
        id bigserial primary key not null,
        value bigint default 1
      );
    SQL
  end

  let!(:model) do
    define_batchable_model('_test_gitlab_main_data', connection: ApplicationRecord.connection).tap do |model|
      model.include(described_class)
      model.columns_changing_default(:value)
      model.columns # Force the schema cache to populate
    end
  end

  def alter_default(new_default)
    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE _test_gitlab_main_data ALTER COLUMN value SET DEFAULT #{new_default}
    SQL
  end

  def recorded_insert_queries(&block)
    recorder = ActiveRecord::QueryRecorder.new
    recorder.record(&block)

    recorder.log.select { |q| q.include?('INSERT INTO') }
  end

  def query_includes_value_column?(query)
    parsed = PgQuery.parse(query)
    parsed.tree.stmts.first.stmt.insert_stmt.cols.any? { |node| node.res_target.name == 'value' }
  end

  it 'forces the column to be written on a change' do
    queries = recorded_insert_queries do
      model.create!(value: 1)
    end

    expect(queries.length).to eq(1)

    expect(query_includes_value_column?(queries.first)).to be_truthy
  end

  it 'does not write the column without a change' do
    queries = recorded_insert_queries do
      model.create!
    end

    expect(queries.length).to eq(1)
    expect(query_includes_value_column?(queries.first)).to be_falsey
  end

  it 'does not send the old column value if the default has changed' do
    alter_default(2)
    model.create!

    expect(model.pluck(:value)).to contain_exactly(2)
  end

  it 'prevents writing new default in place of the old default' do
    alter_default(2)

    model.create!(value: 1)

    expect(model.pluck(:value)).to contain_exactly(1)
  end
end
