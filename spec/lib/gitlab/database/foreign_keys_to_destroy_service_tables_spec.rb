# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'foreign keys to tables with destroy services', feature_category: :database do
  let(:tables_to_services) { Gitlab::Database::TablesWithDestroyServices.tables_to_services }
  let(:todo_file_path) { 'spec/support/database/destroy_service_foreign_keys_todo.yml' }
  let(:todo_list) { YAML.safe_load_file(Rails.root.join(todo_file_path)) }

  it 'expects destroy services to handle new dependent records', :aggregate_failures do
    foreign_keys_to_guarded_tables.each do |foreign_key|
      to_table = foreign_key.referenced_table_name
      entry = todo_entry_for(foreign_key)
      services = tables_to_services[to_table]
      handled = handled_by_all_services?(services, foreign_key.constrained_table_name)

      if todo_list[to_table]&.include?(entry)
        expect(handled).to be(false),
          "#{services.join(' and ')} now handles `#{foreign_key.constrained_table_name}`. " \
            "Remove #{entry} from #{todo_file_path}."
        next
      end

      expect(handled).to be(true), failure_message(foreign_key, services)
    end
  end

  it 'does not keep stale entries in the todo list', :aggregate_failures do
    current_entries = foreign_keys_to_guarded_tables.group_by(&:referenced_table_name)
      .transform_values { |fks| fks.map { |fk| todo_entry_for(fk) } }

    todo_list.each do |to_table, entries|
      # Tables owned by EE-only destroy services are not guarded on FOSS, so
      # their entries can only be verified on EE pipelines.
      next unless tables_to_services.key?(to_table)

      entries.each do |entry|
        expect(current_entries[to_table]).to include(entry),
          "The foreign key `#{entry}` referencing `#{to_table}` no longer exists. " \
            "Remove its entry from #{todo_file_path}."
      end
    end
  end

  it 'does not keep stale handles_removal_of declarations', :aggregate_failures do
    services_to_tables = tables_to_services.each_with_object({}) do |(table, services), map|
      services.each { |service| (map[service] ||= []) << table }
    end

    services_to_tables.each do |service_name, owned_tables|
      service_class = service_name.safe_constantize
      next unless service_class.respond_to?(:own_handled_tables)

      constrained_tables = foreign_keys_to_guarded_tables
        .select { |fk| owned_tables.include?(fk.referenced_table_name) }
        .map(&:constrained_table_name)

      # Own declarations only: inherited ones are validated against the class
      # that declared them, not against every subclass's owned tables.
      service_class.own_handled_tables.each do |declared_table|
        expect(constrained_tables).to include(declared_table),
          "#{service_name} declares `handles_removal_of :#{declared_table}`, but no foreign key from " \
            "`#{declared_table}` references #{owned_tables.join(' or ')} anymore. Remove the stale " \
            "declaration."
      end
    end
  end

  def foreign_keys_to_guarded_tables
    @foreign_keys_to_guarded_tables ||= Gitlab::Database::PostgresForeignKey
      .not_inherited
      .by_referenced_table_name(tables_to_services.keys)
  end

  def todo_entry_for(foreign_key)
    "#{foreign_key.constrained_table_name}.#{Array(foreign_key.constrained_columns).join(',')}"
  end

  # Every owning service can delete rows of the referenced table
  # independently, so each of them must handle the dependent records.
  def handled_by_all_services?(services, constrained_table)
    services.all? do |service_name|
      service_class = service_name.safe_constantize
      next false unless service_class

      service_class.respond_to?(:handled_tables) && service_class.handled_tables.include?(constrained_table)
    end
  end

  def failure_message(foreign_key, services)
    entry = todo_entry_for(foreign_key)
    to_table = foreign_key.referenced_table_name
    service = services.join(' and ')

    "Foreign key `#{foreign_key.name}` (#{entry}) references `#{to_table}`, whose records are deleted " \
      "through #{service}. Each of these services must delete or otherwise clean up the dependent " \
      "records itself; the database-level cascade is only a backstop for manual admin deletes and does " \
      "not run application cleanup. Once every listed service handles this, add " \
      "`include Gitlab::HandlesRemovalOf` and `handles_removal_of :#{foreign_key.constrained_table_name}` " \
      "to each of them. Alternatively, if this foreign key predates this rule, or a cascade-only delete " \
      "is genuinely intended, add #{entry} under #{to_table} in #{todo_file_path} with a comment " \
      "explaining why."
  end
end
