# frozen_string_literal: true

module Tooling
  module Danger
    module Multiversion
      # Query documents under app/graphql/queries are client-side: the frontend imports them through
      # the `shared_queries` build alias (config/helpers/aliases.js), so they count as frontend even
      # though they live in the backend tree. They are excluded from GRAPHQL_BACKEND_REGEX below,
      # otherwise touching one alone would satisfy both sides of the check.
      FRONTEND_REGEX = %r{\A((ee|jh)/)?(app/assets/.*\.(vue|js|graphql)|app/graphql/queries/.*\.graphql)\z}
      GRAPHQL_BACKEND_REGEX = %r{\A((ee|jh)/)?app/graphql/(?!queries/)}

      # A schema change does not have to touch app/graphql: roughly a hundred enums take their values
      # from constants and collections defined in app/models, app/finders, app/services and lib. Both
      # files below are generated from the live schema and committed, and `graphql-verify` fails when
      # either is stale, so a schema change of any origin has to show up in one of them.
      SCHEMA_ARTIFACT_REGEX = Regexp.union(
        %r{\Adoc/api/graphql/reference/},
        %r{\Aapp/assets/javascripts/graphql_shared/possible_types\.json\z}
      )

      WARNING = 'This change updates both GraphQL backend and frontend code, which can break ' \
        'the canary stage during a rolling deployment. Please read the **Multiversion compatibility** ' \
        'section below before merging.'

      # A local run has no merge request to read a target branch from, so Danger compares against
      # `origin/master`. On a branch that targets anything else the comparison picks up the target's
      # own changes, which can make this check fire on files the author never touched.
      LOCAL_BASE_HINT = 'If this branch targets a branch other than `master`, compare against it ' \
        'with `DANGER_LOCAL_BASE=<target-branch> git push`.'

      def check!
        return unless frontend_changed? && backend_changed?

        markdown <<~MARKDOWN
        ## ⚠️ Multiversion compatibility

        This change updates **both GraphQL backend and frontend code**.
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

        warn(warning_message)
      end

      private

      def warning_message
        return WARNING if helper.ci?

        "#{WARNING} #{LOCAL_BASE_HINT}"
      end

      def frontend_changed?
        changed_files.grep(FRONTEND_REGEX).any?
      end

      def backend_changed?
        changed_files.grep(GRAPHQL_BACKEND_REGEX).any? || changed_files.grep(SCHEMA_ARTIFACT_REGEX).any?
      end

      def changed_files
        git.modified_files + git.added_files
      end
    end
  end
end
