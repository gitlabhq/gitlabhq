# frozen_string_literal: true

module Support
  module PermissionsCheck
    def self.inject(mod)
      mod.prepend PermissionsExtension if Gitlab::Utils.to_boolean(ENV['GITLAB_DEBUG_POLICIES'])
    end

    module PermissionsExtension
      def before_check(policy, ability, _user, _subject, _opts)
        puts(
          "POLICY CHECK DEBUG -> " \
          "policy: #{policy.class.name}, ability: #{ability}, called_from: #{caller_locations(2, 5)}"
        )
      end
    end
  end
end
