# frozen_string_literal: true

module Tooling
  module Danger
    module Multiversion
      FRONTEND_REGEX = %r{\A((ee|jh)/)?app/assets/.*(\.(vue|js|graphql))\z}
      GRAPHQL_BACKEND_REGEX = %r{\A((ee|jh)/)?app/graphql/}

      def check!
        return unless helper.ci?
        return unless frontend_changed? && backend_changed?

        markdown <<~MARKDOWN
        ## Multiversion compatibility

        This merge request updates GraphQL backend and frontend code.

        To prevent an incident, ensure the updated frontend code is backwards compatible.

        For more information, see the [multiversion compatibility documentation](https://docs.gitlab.com/ee/development/graphql_guide/reviewing.html#multiversion-compatibility).
        MARKDOWN
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
