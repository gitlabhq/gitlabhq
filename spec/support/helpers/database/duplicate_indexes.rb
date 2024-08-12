# frozen_string_literal: true

module Database
  class DuplicateIndexes
    attr_accessor :table_name, :indexes

    BTREE_INDEX_STRUCT = Struct.new(:name, :columns, :unique)

    def initialize(table_name, indexes)
      @table_name = table_name
      @indexes = indexes
    end

    def duplicate_indexes
      ret = {}

      btree_indexes.each do |btree_index|
        matching_indexes = matching_indexes_for(btree_index)
        next unless matching_indexes.any?

        ret[btree_index] = matching_indexes
      end

      ret
    end

    def self.btree_index_struct(index)
      columns =
        if ::Gitlab.next_rails?
          Array.wrap(index.columns) + Array.wrap(index.include)
        else
          Array.wrap(index.columns)
        end

      BTREE_INDEX_STRUCT.new(
        index.name,
        columns.map do |column|
          # https://apidock.com/rails/ActiveRecord/ConnectionAdapters/PostgreSQL/SchemaStatements/indexes
          # asc is the default order
          column_order = index.orders.is_a?(Symbol) ? index.orders : (index.orders[column] || :asc)
          { name: column, order: column_order }
        end,
        index.unique
      )
    end

    private

    def btree_indexes
      return @btree_indexes if @btree_indexes

      # We only scan non-conditional btree indexes
      @btree_indexes = indexes.select do |index|
        index.using == :btree && index.where.nil? && index.opclasses.blank?
      end

      @btree_indexes = @btree_indexes.map { |index| self.class.btree_index_struct(index) }
    end

    def matching_indexes_for(btree_index)
      all_matching_indexes = []

      # When comparing btree_index with other_index. btree_index is the index that can have more columns
      # than the other_index.
      (1..btree_index.columns.length).each do |subset_length|
        columns = btree_index.columns.first(subset_length)
        matching_indexes = btree_indexes.reject { |other_index| other_index == btree_index }.select do |other_index|
          other_index.columns == columns
        end

        # For now we ignore other indexes that are UNIQUE and have a matching columns subset of
        # the btree_index columns, as UNIQUE indexes are still needed to enforce uniqueness
        # constraints on subset of the columns.
        matching_indexes = matching_indexes.reject do |other_index|
          (other_index.unique && (other_index.columns.length < btree_index.columns.length))
        end

        all_matching_indexes += matching_indexes
      end

      all_matching_indexes
    end
  end
end
