# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::ConvertToBigint, feature_category: :database do
  let(:migration) do
    Class
      .new
      .include(described_class)
      .include(Gitlab::Database::MigrationHelpers)
      .new
  end

  describe '#com_or_dev_or_test_but_not_jh?' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :dev_or_test, :jh, :expectation) do
      true  | true  | true  | true
      true  | false | true  | false
      false | true  | true  | true
      false | false | true  | false
      true  | true  | false | true
      true  | false | false | true
      false | true  | false | true
      false | false | false | false
    end

    with_them do
      it 'returns true for GitLab.com (but not JH), dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)
        allow(Gitlab).to receive(:jh?).and_return(jh)

        expect(migration.com_or_dev_or_test_but_not_jh?).to eq(expectation)
      end
    end
  end

  describe '#temp_column_removed?' do
    it 'return true when column is not present' do
      expect(migration).to receive(:column_exists?).with('test_table', 'id_convert_to_bigint').and_return(false)

      expect(migration.temp_column_removed?(:test_table, :id)).to eq(true)
    end

    it 'return false when column present' do
      expect(migration).to receive(:column_exists?).with('test_table', 'id_convert_to_bigint').and_return(true)

      expect(migration.temp_column_removed?(:test_table, :id)).to eq(false)
    end
  end

  describe '#columns_swapped?' do
    it 'returns true if columns are already swapped' do
      columns = [
        Struct.new(:name, :sql_type).new('id', 'bigint'),
        Struct.new(:name, :sql_type).new('id_convert_to_bigint', 'integer')
      ]

      expect(migration).to receive(:columns).with('test_table').and_return(columns)

      expect(migration.columns_swapped?(:test_table, :id)).to eq(true)
    end

    it 'returns false if columns are not yet swapped' do
      columns = [
        Struct.new(:name, :sql_type).new('id', 'integer'),
        Struct.new(:name, :sql_type).new('id_convert_to_bigint', 'bigint')
      ]

      expect(migration).to receive(:columns).with('test_table').and_return(columns)

      expect(migration.columns_swapped?(:test_table, :id)).to eq(false)
    end
  end
end
