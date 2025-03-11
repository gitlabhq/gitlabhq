# frozen_string_literal: true

module GraphQL
  # This module exposes Fiber-level runtime information.
  #
  # It won't work across unrelated fibers, although it will work in child Fibers.
  #
  # @example Setting Up ActiveRecord::QueryLogs
  #
  #   config.active_record.query_log_tags = [
  #     :namespaced_controller,
  #     :action,
  #     :job,
  #     # ...
  #     {
  #       # GraphQL runtime info:
  #       current_graphql_operation: -> { GraphQL::Current.operation_name },
  #       current_graphql_field: -> { GraphQL::Current.field&.path },
  #       current_dataloader_source: -> { GraphQL::Current.dataloader_source_class },
  #       # ...
  #     },
  #   ]
  #
  module Current
    # @return [String, nil] Comma-joined operation names for the currently-running {Multiplex}. `nil` if all operations are anonymous.
    def self.operation_name
      if (m = Fiber[:__graphql_current_multiplex])
        m.context[:__graphql_current_operation_name] ||= begin
          names = m.queries.map { |q| q.selected_operation_name }
          if names.all?(&:nil?)
            nil
          else
            names.join(",")
          end
        end
      else
        nil
      end
    end

    # @see GraphQL::Field#path for a string identifying this field
    # @return [GraphQL::Field, nil] The currently-running field, if there is one.
    def self.field
      Fiber[:__graphql_runtime_info]&.values&.first&.current_field
    end

    # @return [Class, nil] The currently-running {Dataloader::Source} class, if there is one.
    def self.dataloader_source_class
      Fiber[:__graphql_current_dataloader_source]&.class
    end

    # @return [GraphQL::Dataloader::Source, nil] The currently-running source, if there is one
    def self.dataloader_source
      Fiber[:__graphql_current_dataloader_source]
    end
  end
end
