# frozen_string_literal: true

module Tooling
  module Danger
    module HtmlEscapeOnce
      def check_html_escape_once_calls
        added_calls = added_call_paths
        fail message(added_calls) if added_calls.any?
      end

      private

      TARGET_CALL = /\b(?:html_escape_once|escape_once)\b/

      def added_call_paths
        helper.all_changed_files.select do |file|
          next unless file.end_with?('.rb', '.haml', '.erb')
          next if file.start_with?('danger/', 'tooling/', 'spec/tooling/', 'ee/spec/tooling/')

          # Block MRs that (overall) add uses of `html_escape_once` and `escape_once`.
          #
          # Don't block MRs that only _change_ lines containing these.
          # We can't perfectly know if a given + and - pair up, but better to fail safe
          # here than block MRs incorrectly.
          net = 0
          helper.changed_lines(file).grep(TARGET_CALL).each do |line|
            if line.start_with?('+')
              net += line.scan(TARGET_CALL).count
            elsif line.start_with?('-')
              net -= line.scan(TARGET_CALL).count
            end
          end

          net > 0
        end
      end

      def format_added_calls(added_calls)
        added_calls.map { |c| "- `#{c}`" }.join("\n")
      end

      def message(added_calls)
        format(message_template, { added_calls: format_added_calls(added_calls) })
      end

      def message_template
        <<~MSG
          Adding calls to `html_escape_once` or `escape_once` to the codebase is forbidden!
          We are in the process of removing all calls to these methods --- they mix unescaped
          and escaped content in a way which cannot be unmixed, and often leads to XSS.

          We should always know whether any string content is considered text (and _must_ be escaped
          when included in HTML) or HTML (and can be included safely) --- any in-between means we have
          lost track of what can be trusted, and need to revisit the data flow.

          Please remove the added calls to `html_escape_once` or `escape_once`.
          Use `html_escape` if the input is text, and ask for help if you need it!

          Thank you for helping keep GitLab XSS-free!

          Added calls found in:

          %<added_calls>s

          Tracking issue: https://gitlab.com/gitlab-org/gitlab/-/issues/581104
        MSG
      end
    end
  end
end
