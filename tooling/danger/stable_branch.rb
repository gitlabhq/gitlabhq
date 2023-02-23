# frozen_string_literal: true

module Tooling
  module Danger
    module StableBranch
      VersionApiError = Class.new(StandardError)

      STABLE_BRANCH_REGEX = %r{\A(?<version>\d+-\d+)-stable-ee\z}.freeze

      # rubocop:disable Lint/MixedRegexpCaptureTypes
      VERSION_REGEX = %r{
        \A(?<major>\d+)
        \.(?<minor>\d+)
        (\.(?<patch>\d+))?
        (-(?<rc>rc(?<rc_number>\d*)))?
        (-\h+\.\h+)?
        (-ee|\.ee\.\d+)?\z
      }x.freeze
      # rubocop:enable Lint/MixedRegexpCaptureTypes

      MAINTENANCE_POLICY_URL = 'https://docs.gitlab.com/ee/policy/maintenance.html'

      MAINTENANCE_POLICY_MESSAGE = <<~MSG
      See the [release and maintenance policy](#{MAINTENANCE_POLICY_URL}) for more information.
      MSG

      FEATURE_ERROR_MESSAGE = <<~MSG
      This MR includes the `type::feature` label. Features do not qualify for patch releases. #{MAINTENANCE_POLICY_MESSAGE}
      MSG

      BUG_ERROR_MESSAGE = <<~MSG
      This branch is meant for backporting bug fixes. If this MR qualifies please add the `type::bug` label. #{MAINTENANCE_POLICY_MESSAGE}
      MSG

      VERSION_WARNING_MESSAGE = <<~MSG
      Backporting to older releases requires an [exception request process](https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases)
      MSG

      FAILED_VERSION_REQUEST_MESSAGE = <<~MSG
      There was a problem checking if this is a qualified version for backporting. Re-running this job may fix the problem.
      MSG

      # rubocop:disable Style/SignalException
      def check!
        return unless stable_target_branch && !helper.security_mr?

        fail FEATURE_ERROR_MESSAGE if has_feature_label?
        fail BUG_ERROR_MESSAGE unless has_bug_label?

        warn VERSION_WARNING_MESSAGE unless targeting_patchable_version?
      end
      # rubocop:enable Style/SignalException

      private

      def stable_target_branch
        helper.mr_target_branch.match(STABLE_BRANCH_REGEX)
      end

      def has_feature_label?
        helper.mr_has_labels?('type::feature')
      end

      def has_bug_label?
        helper.mr_has_labels?('type::bug')
      end

      def targeting_patchable_version?
        raise VersionApiError if last_three_minor_versions.empty?

        last_three_minor_versions.include?(targeted_version)
      rescue VersionApiError
        warn FAILED_VERSION_REQUEST_MESSAGE
        true
      end

      def last_three_minor_versions
        return [] unless versions

        current_version = versions.first.match(VERSION_REGEX)
        version_1 = previous_minor_version(current_version)
        version_2 = previous_minor_version(version_1)

        [
          version_to_minor_string(current_version),
          version_to_minor_string(version_1),
          version_to_minor_string(version_2)
        ]
      end

      def targeted_version
        stable_target_branch[1].tr('-', '.')
      end

      def versions(page = 1)
        version_api_endpoint = "https://version.gitlab.com/api/v1/versions?per_page=50&page=#{page}"
        response = HTTParty.get(version_api_endpoint) # rubocop:disable Gitlab/HTTParty

        raise VersionApiError unless response.success?

        version_list = response.parsed_response.map { |v| v['version'] } # rubocop:disable Rails/Pluck

        version_list.sort_by { |v| Gem::Version.new(v) }.reverse
      end

      def previous_minor_version(version)
        previous_minor = version[:minor].to_i - 1

        return "#{version[:major]}.#{previous_minor}".match(VERSION_REGEX) if previous_minor >= 0

        fetch_last_minor_version_for_major(version[:major].to_i - 1)
      end

      def fetch_last_minor_version_for_major(major)
        page = 1
        last_minor_version = nil

        while last_minor_version.nil?
          last_minor_version = versions(page).find do |version|
            version.split('.').first.to_i == major
          end

          break if page > 10

          page += 1
        end

        raise VersionApiError if last_minor_version.nil?

        last_minor_version.match(VERSION_REGEX)
      end

      def version_to_minor_string(version)
        "#{version[:major]}.#{version[:minor]}"
      end
    end
  end
end
