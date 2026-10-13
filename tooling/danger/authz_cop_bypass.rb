# frozen_string_literal: true

require 'digest'
require 'gitlab/dangerfiles/teammate'

require_relative 'suggestor'

module Tooling
  module Danger
    module AuthzCopBypass
      include ::Tooling::Danger::Suggestor

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

      # The authz cops, their specs and this rule's spec quote the directive as test data.
      EXCLUDED_PATHS = %r{\A(?:rubocop/cop/gitlab/authz/|spec/rubocop/cop/gitlab/authz/|spec/tooling/danger/)}

      APPROVERS_GROUP = 'gitlab-org/software-supply-chain-security/authorization/approvers'

      MR_COMMENT = <<~MARKDOWN
        ## Authorization review

        This merge request bypasses an Authorization RuboCop rule (`Gitlab/Authz/*`), either
        inline (`# rubocop:disable`) or by adding a new `.rubocop_todo` exclusion:

        %<file_list>s

        These cops guard against coarse or unsafe permission checks, so silencing one is
        worth a second look. Please confirm the bypass (and its `-- reason`) is justified.

        %<accountable>s

        cc @gitlab-org/software-supply-chain-security/authorization
      MARKDOWN

      ACCOUNTABLE_REVIEWER = '@%<username>s can you please review?'

      LINE_COMMENT = 'This silences a `Gitlab/Authz/*` RuboCop rule, so it needs an ~"authorization" review. ' \
        'See the Authorization review section of the Danger comment for who is reviewing it.'

      NO_ACCOUNTABLE_REVIEWER = 'No ~"authorization" approver is available right now. ' \
        'Please request a review from someone in the group.'

      WARNING = 'This merge request disables a `Gitlab/Authz/*` RuboCop rule. ' \
        'Please request an ~"authorization" review.'

      def add_comment_for_authz_cop_bypass
        # The comment pings the Authorization team, so wait until the MR is ready for review.
        return if helper.draft_mr?

        files = changed_files_with_authz_bypass
        return if files.empty?

        files.each { |filename| add_line_comments(filename) }

        reviewer = accountable_reviewer
        add_reviewer(reviewer) if reviewer && !reviewer_usernames.include?(reviewer['username'])

        accountable = reviewer ? format(ACCOUNTABLE_REVIEWER, username: reviewer['username']) : NO_ACCOUNTABLE_REVIEWER
        markdown(format(MR_COMMENT, file_list: helper.markdown_list(files), accountable: accountable))
        warn(WARNING)
      end

      private

      # An approver who is already a reviewer stays accountable. Otherwise pick one, seeded
      # from the source branch so every pipeline picks the same person.
      def accountable_reviewer
        return unless helper.ci?

        approvers = authz_approvers.sort_by { |approver| approver['username'] }

        approvers.find { |approver| reviewer_usernames.include?(approver['username']) } ||
          approvers.shuffle(random: branch_random).find { |approver| available?(approver) }
      rescue StandardError => e
        warn("Failed to pick an ~\"authorization\" reviewer: #{e.message}")
        nil
      end

      def authz_approvers
        gitlab.api.group_members(APPROVERS_GROUP).auto_paginate
      end

      def reviewer_usernames
        helper.mr_reviewers.map { |reviewer| reviewer['username'] }
      end

      def available?(approver)
        return false if approver['username'] == helper.mr_author

        !!Gitlab::Dangerfiles::Teammate.find_member(approver['username'])&.available
      end

      def branch_random
        Random.new(Digest::SHA256.hexdigest(helper.mr_source_branch).to_i(16))
      end

      def add_reviewer(reviewer)
        reviewer_ids = helper.mr_reviewers.map { |existing| existing['id'] } + [reviewer['id']]

        gitlab.api.update_merge_request(
          gitlab.mr_json['project_id'],
          gitlab.mr_json['iid'],
          reviewer_ids: reviewer_ids
        )
      rescue StandardError => e
        warn("Failed to add @#{reviewer['username']} as a reviewer: #{e.message}")
      end

      def changed_files_with_authz_bypass
        helper.all_changed_files.select do |filename|
          pattern = bypass_pattern(filename)

          pattern && added_line?(filename, pattern)
        end
      end

      def bypass_pattern(filename)
        return if filename.match?(EXCLUDED_PATHS)

        if filename.end_with?('.rb')
          AUTHZ_COP_BYPASS
        elsif filename.match?(AUTHZ_TODO_FILE)
          AUTHZ_TODO_EXCLUSION
        end
      end

      def add_line_comments(filename)
        add_suggestion(filename: filename, regex: bypass_pattern(filename), comment_text: LINE_COMMENT)
      end

      def added_line?(filename, pattern)
        helper.changed_lines(filename).any? do |line|
          line.start_with?('+') && line.match?(pattern)
        end
      end
    end
  end
end
