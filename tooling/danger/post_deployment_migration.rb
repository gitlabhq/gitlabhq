# frozen_string_literal: true

module Tooling
  module Danger
    module PostDeploymentMigration
      MIGRATION_FILES_REGEX = %r{\A(ee/)?db/post_migrate/}

      BYPASS_LABEL = 'patch-release::pdm-approved'

      AUTHORIZED_BYPASS_GROUPS = %w[
        gitlab-org/release/managers
        gitlab-org/delivery
        gitlab-com/gl-security/product-security/psirt-group
      ].freeze

      RUNBOOK_URL = 'https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/security/utilities/post_deployment_migrations.md'

      DEFAULT_BLOCK_MESSAGE = <<~MSG
        ❌ This security MR includes post-deploy migration(s):

        %<files>s

        Post-deploy migrations are not allowed on security MRs — they create a point of no return
        in production. Once executed, rollback becomes unavailable and the only mitigation is
        roll-forward (6+ hours, subject to pipeline failures).

        See the [runbook](%<runbook>s).

        If you believe an exception is justified, follow the escalation process in the runbook
        to request a joint Delivery + PSIRT review.
      MSG

      UNAUTHORIZED_BYPASS_MESSAGE = <<~MSG
        ❌ The `%<label>s` label was applied by @%<applier>s, who is not a member of an
        authorized bypass group. The label has been removed.

        Bypass label may only be applied by a member of one of:
        %<groups>s

        See the [escalation runbook](%<runbook>s).
      MSG

      APPROVED_EXCEPTION_MESSAGE = <<~MSG
        ⚠️ Post-deploy migration exception approved by @%<applier>s.
        This MR ships a post-deploy migration as an approved exception per the joint
        Delivery + PSIRT review process.

        Migration files:
        %<files>s
      MSG

      UNVERIFIABLE_BYPASS_MESSAGE = <<~MSG
        ❌ The `%<label>s` label is present, but its applier could not be verified
        (%<reason>s).

        The label has NOT been removed. Re-run this job once the issue clears; if it
        persists, follow the escalation process in the runbook.

        See the [runbook](%<runbook>s).
      MSG

      def post_deployment_migration_files
        @post_deployment_migration_files ||= helper.all_changed_files.grep(MIGRATION_FILES_REGEX)
      end

      # Main entry point - invoked from danger/post_deployment_migrations/Dangerfile.
      def check_security_post_deployment_migrations
        return unless helper.ci?
        return unless security_merge_request_targeting_default_branch?
        return if post_deployment_migration_files.empty?

        if helper.mr_labels.include?(BYPASS_LABEL)
          handle_bypass_label
        else
          fail_default_block
        end
      end

      private

      def security_merge_request_targeting_default_branch?
        helper.security_mr? && !helper.stable_branch?
      end

      def fail_default_block
        fail format(
          DEFAULT_BLOCK_MESSAGE,
          files: format_file_list,
          runbook: RUNBOOK_URL
        )
      end

      def handle_bypass_label
        applier = bypass_label_applier

        # Could not attribute the label to anyone (no add-event found). Treat as
        # unverifiable: block, but do not destroy a label we can't prove is wrong.
        return fail_unverifiable('the label add-event could not be found') if applier.nil?

        if member_of_authorized_group?(applier)
          post_audit_discussion(approval_audit_body(applier))
          warn format(
            APPROVED_EXCEPTION_MESSAGE,
            applier: applier,
            files: format_file_list
          )
        else
          post_audit_discussion(rejection_audit_body(applier))
          remove_bypass_label
          fail format(
            UNAUTHORIZED_BYPASS_MESSAGE,
            label: BYPASS_LABEL,
            applier: applier,
            groups: AUTHORIZED_BYPASS_GROUPS.map { |g| "  - @#{g}" }.join("\n"),
            runbook: RUNBOOK_URL
          )
        end
      rescue StandardError => e
        # A verification API call failed. Fail closed (block the MR) but never
        # strip the label on an error we can't attribute to the applier.
        fail_unverifiable("verification API call failed: #{e.message}")
      end

      def fail_unverifiable(reason)
        fail format(
          UNVERIFIABLE_BYPASS_MESSAGE,
          label: BYPASS_LABEL,
          reason: reason,
          runbook: RUNBOOK_URL
        )
      end

      # Raises on API failure; handle_bypass_label's rescue turns that into an
      # "unverifiable" outcome (fail without removing the label).
      def bypass_label_applier
        events = gitlab.api.merge_request_label_events(
          gitlab.mr_json['project_id'],
          gitlab.mr_json['iid']
        ).auto_paginate

        last_add = events.reverse.find do |event|
          label = event['label']
          event['action'] == 'add' && label && label['name'] == BYPASS_LABEL
        end
        return unless last_add

        user = last_add['user']
        user && user['username']
      end

      def member_of_authorized_group?(username)
        AUTHORIZED_BYPASS_GROUPS.any? { |group_path| group_member?(group_path, username) }
      end

      def group_member?(group_path, username)
        members = gitlab.api.group_members(group_path).auto_paginate
        members.any? { |m| m['username'] == username }
      end

      def remove_bypass_label
        gitlab.api.update_merge_request(
          gitlab.mr_json['project_id'],
          gitlab.mr_json['iid'],
          remove_labels: BYPASS_LABEL
        )
      rescue StandardError => e
        warn "Failed to remove unauthorized bypass label: #{e.message}"
      end

      # Post a fresh MR discussion thread capturing the bypass event.
      # Danger's own summary comment is edited in place across runs; this
      # thread is never edited, giving security auditors a permanent record
      # of who applied the bypass label and when.
      def post_audit_discussion(body)
        gitlab.api.create_merge_request_discussion(
          gitlab.mr_json['project_id'],
          gitlab.mr_json['iid'],
          body: body
        )
      rescue StandardError => e
        warn "Failed to post PDM audit discussion note: #{e.message}"
      end

      def approval_audit_body(applier)
        <<~BODY
          🔓 **Post-deploy migration bypass approved** by @#{applier} at #{Time.now.utc.iso8601}.

          Migration files:
          #{format_file_list}
        BODY
      end

      def rejection_audit_body(applier)
        authorized_list = AUTHORIZED_BYPASS_GROUPS.map { |g| "`@#{g}`" }.join(', ')
        <<~BODY
          🔒 **Post-deploy migration bypass attempt** by @#{applier || 'unknown'} at #{Time.now.utc.iso8601}. Not a member of #{authorized_list}. The `#{BYPASS_LABEL}` label has been removed.
        BODY
      end

      def format_file_list
        post_deployment_migration_files.map { |f| "- `#{f}`" }.join("\n")
      end
    end
  end
end
