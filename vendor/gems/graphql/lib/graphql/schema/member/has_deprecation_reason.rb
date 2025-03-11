# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasDeprecationReason
        # @return [String, nil] Explains why this member was deprecated (if present, this will be marked deprecated in introspection)
        attr_reader :deprecation_reason

        # Set the deprecation reason for this member, or remove it by assigning `nil`
        # @param text [String, nil]
        def deprecation_reason=(text)
          @deprecation_reason = text
          if text.nil?
            remove_directive(GraphQL::Schema::Directive::Deprecated)
          else
            # This removes a previously-attached directive, if there is one:
            directive(GraphQL::Schema::Directive::Deprecated, reason: text)
          end
        end
      end
    end
  end
end
