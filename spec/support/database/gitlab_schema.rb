# frozen_string_literal: true

# This module gathes information about table to schema mapping
# to understand table affinity
module Database
  module GitlabSchema
    def self.table_schemas(tables)
      tables.map { |table| table_schema(table) }.to_set
    end

    def self.table_schema(name)
      tables_to_schema[name] || :undefined
    end

    def self.tables_to_schema
      @tables_to_schema ||= all_classes_with_schema.to_h do |klass|
        [klass.table_name, klass.gitlab_schema]
      end
    end

    def self.all_classes_with_schema
      ActiveRecord::Base.descendants.reject(&:abstract_class?).select(&:gitlab_schema?) # rubocop:disable Database/MultipleDatabases
    end
  end
end
