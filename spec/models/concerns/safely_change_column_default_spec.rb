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

  def drop_default
    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE _test_gitlab_main_data ALTER COLUMN value DROP DEFAULT
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

  it 'writes the column even without a user-supplied value', :aggregate_failures do
    queries = recorded_insert_queries do
      model.create!
    end

    expect(queries.length).to eq(1)
    expect(query_includes_value_column?(queries.first)).to be_truthy
  end

  it 'writes the in-memory default rather than relying on the changed DB default' do
    alter_default(2)
    model.create!

    # The schema cache still holds the original default (1), so that value is written explicitly instead of
    # falling back to the new DB default (2). This keeps a column whose default is in flux out of the DB default.
    expect(model.pluck(:value)).to contain_exactly(1)
  end

  it 'writes the in-memory default rather than NULL when the DB default is dropped' do
    drop_default
    model.create!

    # Reproduces INC-11487: dropping the default without refreshing the stale schema cache must not leave the
    # column to the (now absent) DB default, which would insert NULL.
    expect(model.pluck(:value)).to contain_exactly(1)
  end

  it 'prevents writing new default in place of the old default' do
    alter_default(2)

    model.create!(value: 1)

    expect(model.pluck(:value)).to contain_exactly(1)
  end

  it 'writes a code-owned attribute default even when it matches a dropped DB default' do
    # The exact INC-11487 shape: the attribute default matches the DB default (so partial_inserts would omit it)
    # and the DB default has since been dropped. The concern forces the column in, so the value is written, not NULL.
    model = define_batchable_model('_test_gitlab_main_data', connection: ApplicationRecord.connection).tap do |m|
      m.include(described_class)
      m.attribute(:value, :integer, default: 1)
      m.columns_changing_default(:value)
      m.columns # Force the schema cache to populate
    end
    drop_default

    model.create!

    expect(model.pluck(:value)).to contain_exactly(1)
  end

  context 'when a default is added where none existed' do
    # change_column_default(from: nil, to: X). A process may run before or after the migration, so it cannot rely
    # on the DB default; the attribute default supplies the value and the concern ensures it is written.
    after do
      ApplicationRecord.connection.schema_cache.clear!
    end

    it 'writes the attribute default rather than the newly added DB default' do
      drop_default
      ApplicationRecord.connection.schema_cache.clear!

      model = define_batchable_model('_test_gitlab_main_data', connection: ApplicationRecord.connection).tap do |m|
        m.include(described_class)
        m.attribute(:value, :integer, default: 5)
        m.columns_changing_default(:value)
        m.columns # Force the schema cache to populate (no DB default yet)
      end

      alter_default(5) # migration adds the default; this process still holds the stale (no-default) cache

      model.create!

      expect(model.pluck(:value)).to contain_exactly(5)
    end
  end
end
