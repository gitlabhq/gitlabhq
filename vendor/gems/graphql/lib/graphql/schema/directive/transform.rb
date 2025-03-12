# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      # An example directive to show how you might interact with the runtime.
      #
      # This directive takes the return value of the tagged part of the query,
      # and if the named transform is whitelisted and applies to the return value,
      # it's applied by calling a method with that name.
      #
      # @example Installing the directive
      #   class MySchema < GraphQL::Schema
      #     directive(GraphQL::Schema::Directive::Transform)
      #   end
      #
      # @example Transforming strings
      #   viewer {
      #     username @transform(by: "upcase")
      #   }
      class Transform < Schema::Directive
        description "Directs the executor to run named transform on the return value."

        locations(
          GraphQL::Schema::Directive::FIELD,
        )

        argument :by, String,
          description: "The name of the transform to run if applicable"

        TRANSFORMS = [
          "upcase",
          "downcase",
          # ??
        ]
        # Implement the Directive API
        def self.resolve(object, arguments, context)
          path = context.namespace(:interpreter)[:current_path]
          return_value = yield
          transform_name = arguments[:by]
          if TRANSFORMS.include?(transform_name) && return_value.respond_to?(transform_name)
            return_value = return_value.public_send(transform_name)
            response = context.namespace(:interpreter_runtime)[:runtime].final_result
            *keys, last = path
            keys.each do |key|
              if response && (response = response[key])
                next
              else
                break
              end
            end
            if response
              response[last] = return_value
            end
            nil
          end
        end
      end
    end
  end
end
