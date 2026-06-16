# frozen_string_literal: true

module Tooling
  module Danger
    module CiServerFqdn
      # Matches CI YAML files that are part of the pipeline definition:
      #   - .gitlab-ci.yml / .gitlab-ci.yaml at the root
      #   - Any .yml/.yaml file under .gitlab/ci/ (but NOT under .gitlab/ci/includes/gitlab-com/,
      #     which is intentionally GitLab.com-specific)
      CI_YAML_PATTERN = %r{
        \A\.gitlab-ci\.ya?ml\z |
        \A\.gitlab/ci/(?!includes/gitlab-com/).*\.ya?ml\z
      }x

      CI_SERVER_FQDN_PATTERN = /\$\{?CI_SERVER_FQDN\}?/

      def check_ci_server_fqdn_usage
        changed_files = ci_server_fqdn_changed_files
        return if changed_files.empty?

        warn '`$CI_SERVER_FQDN` was added to CI job definitions outside of `.gitlab/ci/includes/gitlab-com/`.'

        markdown(<<~MARKDOWN)
          ## `$CI_SERVER_FQDN` added to CI files

          The following files add `$CI_SERVER_FQDN` to CI job definitions:

          * #{changed_files.map { |path| "`#{path}`" }.join("\n* ")}

          **Are you aware this job will also run on other internal GitLab instances
          (e.g., `dev.gitlab.org`) and on forks, not just GitLab.com?**

          If the job is intended to run only on GitLab.com, move it into
          `.gitlab/ci/includes/gitlab-com/` to make its scope explicit and
          prevent failures on other instances.
        MARKDOWN
      end

      private

      def ci_server_fqdn_changed_files
        helper.all_changed_files.select do |file|
          next unless file.match?(CI_YAML_PATTERN)

          helper.changed_lines(file).any? do |line|
            line.start_with?('+') && line.match?(CI_SERVER_FQDN_PATTERN)
          end
        end
      end
    end
  end
end
