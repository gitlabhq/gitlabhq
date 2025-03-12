# frozen_string_literal: true

module GraphQL
  module Execution
    class Errors
      # Register this handler, updating the
      # internal handler index to maintain least-to-most specific.
      #
      # @param error_class [Class<Exception>]
      # @param error_handlers [Hash]
      # @param error_handler [Proc]
      # @return [void]
      def self.register_rescue_from(error_class, error_handlers, error_handler)
        subclasses_handlers = {}
        this_level_subclasses = []
        # During this traversal, do two things:
        # - Identify any already-registered subclasses of this error class
        #   and gather them up to be inserted _under_ this class
        # - Find the point in the index where this handler should be inserted
        #   (That is, _under_ any superclasses, or at top-level, if there are no superclasses registered)
        while (error_handlers) do
          this_level_subclasses.clear
          # First, identify already-loaded handlers that belong
          # _under_ this one. (That is, they're handlers
          # for subclasses of `error_class`.)
          error_handlers.each do |err_class, handler|
            if err_class < error_class
              subclasses_handlers[err_class] = handler
              this_level_subclasses << err_class
            end
          end
          # Any handlers that we'll be moving, delete them from this point in the index
          this_level_subclasses.each do |err_class|
            error_handlers.delete(err_class)
          end

          # See if any keys in this hash are superclasses of this new class:
          next_index_point = error_handlers.find { |err_class, handler| error_class < err_class }
          if next_index_point
            error_handlers = next_index_point[1][:subclass_handlers]
          else
            # this new handler doesn't belong to any sub-handlers,
            # so insert it in the current set of `handlers`
            break
          end
        end
        # Having found the point at which to insert this handler,
        # register it and merge any subclass handlers back in at this point.
        this_class_handlers = error_handlers[error_class]
        this_class_handlers[:handler] = error_handler
        this_class_handlers[:subclass_handlers].merge!(subclasses_handlers)
        nil
      end

      # @return [Proc, nil] The handler for `error_class`, if one was registered on this schema or inherited
      def self.find_handler_for(schema, error_class)
        handlers = schema.error_handlers[:subclass_handlers]
        handler = nil
        while (handlers) do
          _err_class, next_handler = handlers.find { |err_class, handler| error_class <= err_class }
          if next_handler
            handlers = next_handler[:subclass_handlers]
            handler = next_handler
          else
            # Don't reassign `handler` --
            # let the previous assignment carry over outside this block.
            break
          end
        end

        # check for a handler from a parent class:
        if schema.superclass.respond_to?(:error_handlers)
          parent_handler = find_handler_for(schema.superclass, error_class)
        end

        # If the inherited handler is more specific than the one defined here,
        # use it.
        # If it's a tie (or there is no parent handler), use the one defined here.
        # If there's an inherited one, but not one defined here, use the inherited one.
        # Otherwise, there's no handler for this error, return `nil`.
        if parent_handler && handler && parent_handler[:class] < handler[:class]
          parent_handler
        elsif handler
          handler
        elsif parent_handler
          parent_handler
        else
          nil
        end
      end
    end
  end
end
