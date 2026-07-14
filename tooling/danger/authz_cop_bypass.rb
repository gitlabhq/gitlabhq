# frozen_string_literal: true

module Tooling
  module Danger
    module AuthzCopBypass
      # Matches an inline RuboCop disable/todo directive that names an Authorization
      # cop, for example a comment ending in `Gitlab/Authz/PermissionCheck -- reason`,
      # including the case where the authz cop is one of several cops in the list.
      #
      # The `Gitlab/Authz/*` cops (see rubocop/cop/gitlab/authz/) enforce the
      # permission-check rules. Disabling one is the deliberate bypass we want the
      # Authorization team to see, rather than every routine `can?` call.
      AUTHZ_COP_BYPASS = %r{#\s*rubocop\s*:\s*(?:disable|todo)\s+[\w/,\s]*Gitlab/Authz/}

      # Matches a `.rubocop_todo` file for an Authorization cop. GitLab splits the todo by
      # cop (see .rubocop_todo/gitlab/authz/), so the cop is encoded in the path and we can
      # flag a bypass without parsing the YAML.
      AUTHZ_TODO_FILE = %r{\A\.rubocop_todo/gitlab/authz/.+\.yml\z}

      # Matches an added `Exclude` entry in a todo file, for example `+    - 'app/foo.rb'`.
      # Excluding a file there silences the same authz cop as an inline disable.
      AUTHZ_TODO_EXCLUSION = %r{\A\+\s*-\s*['"]}

      MR_COMMENT = <<~MARKDOWN
        ## Authorization review

        This merge request bypasses an Authorization RuboCop rule (`Gitlab/Authz/*`), either
        inline (`# rubocop:disable`) or by adding a new `.rubocop_todo` exclusion:

        %<file_list>s

        These cops guard against coarse or unsafe permission checks, so silencing one is
        worth a second look. Please request a review from the ~"authorization" group and
        confirm the bypass (and its `-- reason`) is justified.

        cc @gitlab-org/software-supply-chain-security/authorization
      MARKDOWN

      WARNING = 'This merge request disables a `Gitlab/Authz/*` RuboCop rule. ' \
        'Please request an ~"authorization" review.'

      def add_comment_for_authz_cop_bypass
        files = changed_files_with_authz_bypass
        return if files.empty?

        markdown(format(MR_COMMENT, file_list: helper.markdown_list(files)))
        warn(WARNING)
      end

      private

      def changed_files_with_authz_bypass
        helper.all_changed_files.select do |filename|
          if filename.end_with?('.rb')
            added_line?(filename, AUTHZ_COP_BYPASS)
          elsif filename.match?(AUTHZ_TODO_FILE)
            added_line?(filename, AUTHZ_TODO_EXCLUSION)
          else
            false
          end
        end
      end

      def added_line?(filename, pattern)
        helper.changed_lines(filename).any? do |line|
          line.start_with?('+') && line.match?(pattern)
        end
      end
    end
  end
end
