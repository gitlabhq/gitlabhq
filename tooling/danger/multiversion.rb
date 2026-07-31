# frozen_string_literal: true

module Tooling
  module Danger
    module Multiversion
      FRONTEND_REGEX = %r{\A((ee|jh)/)?app/assets/.*(\.(vue|js|graphql))\z}
      GRAPHQL_BACKEND_REGEX = %r{\A((ee|jh)/)?app/graphql/}

      WARNING = 'This merge request updates both GraphQL backend and frontend code, which can break ' \
        'the canary stage during a rolling deployment. Please read the **Multiversion compatibility** ' \
        'section below before merging.'

      def check!
        return unless helper.ci?
        return unless frontend_changed? && backend_changed?

        markdown <<~MARKDOWN
        ## ⚠️ Multiversion compatibility

        This merge request updates **both GraphQL backend and frontend code**.
        This is discouraged when you add new fields or arguments to the GraphQL schema and directly consume them in the frontend.

        ### Why this matters
        During rolling updates/deployments, your frontend code may deploy before the backend changes are fully rolled out.
        This creates a dangerous scenario where:
        - ✅ Frontend requests a new GraphQL field, or sends a new argument
        - ❌ Backend doesn't recognize it yet
        - 💥 **Result: GraphQL errors that can make the application unresponsive**

        ### Recommended approach
        **Split your changes into separate merge requests:**
        1. **First MR**: Add the new GraphQL fields or arguments to the backend
        2. **Second MR**: Update frontend to use them and apply the version directive `@gl_introduced(version: "18.3.0")` to any new field, to prevent the same scenario for Self-Managed customers

        **New arguments have no fallback.** `@gl_introduced` only applies to fields, because GraphQL directives cannot be attached to arguments. An older backend rejects the entire request when it receives an argument it does not know, so either wait for the backend to be fully deployed before merging the frontend change, or gate the frontend behind a feature flag.

        ### Resources
        - [Multiversion compatibility documentation](https://docs.gitlab.com/development/graphql_guide/reviewing/#multiversion-compatibility)
        - [GraphQL version directive documentation](https://docs.gitlab.com/development/api_graphql_styleguide/#multi-version-compatibility)

        **Please review your approach before merging to prevent potential incidents.**
        MARKDOWN

        warn(WARNING)
      end

      private

      def frontend_changed?
        !git.modified_files.grep(FRONTEND_REGEX).empty? || !git.added_files.grep(FRONTEND_REGEX).empty?
      end

      def backend_changed?
        !git.added_files.grep(GRAPHQL_BACKEND_REGEX).empty? || !git.modified_files.grep(GRAPHQL_BACKEND_REGEX).empty?
      end
    end
  end
end
