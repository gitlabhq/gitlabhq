# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      # An example directive to show how you might interact with the runtime.
      #
      # This directive might be used along with a server-side feature flag system like Flipper.
      #
      # With that system, you could use this directive to exclude parts of a query
      # if the current viewer doesn't have certain flags enabled.
      # (So, this flag would be for internal clients, like your iOS app, not third-party API clients.)
      #
      # To use it, you have to implement `.enabled?`, for example:
      #
      # @example Implementing the Feature directive
      #   # app/graphql/directives/feature.rb
      #   class Directives::Feature < GraphQL::Schema::Directive::Feature
      #     def self.enabled?(flag_name, _obj, context)
      #       # Translate some GraphQL data for Ruby:
      #       flag_key = flag_name.underscore
      #       current_user = context[:viewer]
      #       # Check the feature flag however your app does it:
      #       MyFeatureFlags.enabled?(current_user, flag_key)
      #     end
      #   end
      #
      # @example Flagging a part of the query
      #   viewer {
      #     # This field only runs if `.enabled?("recommendationEngine", obj, context)`
      #     # returns true. Otherwise, it's treated as if it didn't exist.
      #     recommendations @feature(flag: "recommendationEngine") {
      #       name
      #       rating
      #     }
      #   }
      class Feature < Schema::Directive
        description "Directs the executor to run this only if a certain server-side feature is enabled."

        locations(
          GraphQL::Schema::Directive::FIELD,
          GraphQL::Schema::Directive::FRAGMENT_SPREAD,
          GraphQL::Schema::Directive::INLINE_FRAGMENT
        )

        argument :flag, String,
          description: "The name of the feature to check before continuing"

        # Implement the Directive API
        def self.include?(object, arguments, context)
          flag_name = arguments[:flag]
          self.enabled?(flag_name, object, context)
        end

        # Override this method in your app's subclass of this directive.
        #
        # @param flag_name [String] The client-provided string of a feature to check
        # @param object [GraphQL::Schema::Objct] The currently-evaluated GraphQL object instance
        # @param context [GraphQL::Query::Context]
        # @return [Boolean] If truthy, execution will continue
        def self.enabled?(flag_name, object, context)
          raise GraphQL::RequiredImplementationMissingError, "Implement `.enabled?(flag_name, object, context)` to return true or false for the feature flag (#{flag_name.inspect})"
        end
      end
    end
  end
end
