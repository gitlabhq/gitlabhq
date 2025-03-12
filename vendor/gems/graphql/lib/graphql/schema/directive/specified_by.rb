# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      class SpecifiedBy < GraphQL::Schema::Directive
        description "Exposes a URL that specifies the behavior of this scalar."
        locations(GraphQL::Schema::Directive::SCALAR)
        default_directive true

        argument :url, String, description: "The URL that specifies the behavior of this scalar."
      end
    end
  end
end
