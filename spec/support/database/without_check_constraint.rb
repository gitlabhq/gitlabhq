# frozen_string_literal: true

# Temporarily disable the named constraint on the table within the block.
#
# without_constraint('members', 'check_1234') do
#   create_invalid_data
# end
module Database
  module WithoutCheckConstraint
    def without_check_constraint(table, name, connection:)
      saved_constraint = constraint(table, name, connection)

      constraint_error!(table, name, connection) if saved_constraint.nil?

      begin
        connection.remove_check_constraint(table, name: name)
        connection.transaction do
          yield
          raise ActiveRecord::Rollback
        end
      ensure
        restore_constraint(saved_constraint, connection)
      end
    end

    private

    def constraint_error!(table, name, connection)
      msg = if connection.table_exists?(table)
              "'#{table}' table does not contain constraint called '#{name}'"
            else
              "'#{table}' does not exist"
            end

      raise msg
    end

    def constraint(table, name, connection)
      connection
        .check_constraints(table)
        .find { |constraint| constraint.options[:name] == name }
    end

    def restore_constraint(constraint, connection)
      connection.add_check_constraint(
        constraint.table_name,
        constraint.expression,
        **constraint.options
      )
    end
  end
end
