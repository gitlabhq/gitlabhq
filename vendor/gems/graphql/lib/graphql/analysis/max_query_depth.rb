# frozen_string_literal: true
module GraphQL
  module Analysis
    class MaxQueryDepth < QueryDepth
      def result
        configured_max_depth = if query
          query.max_depth
        else
          multiplex.schema.max_depth
        end

        if configured_max_depth && @max_depth > configured_max_depth
          GraphQL::AnalysisError.new("Query has depth of #{@max_depth}, which exceeds max depth of #{configured_max_depth}")
        else
          nil
        end
      end
    end
  end
end
