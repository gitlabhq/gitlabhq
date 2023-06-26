# frozen_string_literal: true

require 'gitlab/utils/all'

module Support
  module AbilityCheck
    def self.inject(mod)
      mod.prepend AbilityExtension
    end

    module AbilityExtension
      def before_check(policy, ability, user, subject, opts)
        return super if Checker.ok?(policy, ability)

        ActiveSupport::Deprecation.warn(<<~WARNING)
          Ability #{ability.inspect} in #{policy.class} not found.
          user=#{user.inspect}, subject=#{subject}, opts=#{opts.inspect}"

          To exclude this check add this entry to #{Checker::TODO_YAML}:
          #{policy.class}:
          - #{ability}
        WARNING
      end
    end

    module Checker
      include Gitlab::Utils::StrongMemoize
      extend self

      TODO_YAML = File.join(__dir__, 'ability_check_todo.yml')

      def ok?(policy, ability)
        ignored?(policy, ability) || ability_found?(policy, ability)
      end

      private

      def ignored?(policy, ability)
        todo_list[policy.class.name]&.include?(ability.to_s)
      end

      # Use Policy#has_ability? instead after it has been accepted and released.
      # See https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/issues/25
      def ability_found?(policy, ability)
        # NilPolicy has no abilities. Ignore it.
        return true if policy.is_a?(DeclarativePolicy::NilPolicy)

        # Search in current policy first
        return true if policy.class.ability_map.map.key?(ability)

        # Search recursively in all delegations otherwise.
        # This is potentially slow.
        # Stolen from:
        # https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/d691e/lib/declarative_policy/base.rb#L360-369
        policy.class.delegations.any? do |_, block|
          new_subject = policy.instance_eval(&block)
          new_policy = policy.policy_for(new_subject)

          ability_found?(new_policy, ability)
        end
      end

      def todo_list
        hash = YAML.load_file(TODO_YAML)
        return {} unless hash.is_a?(Hash)

        hash.transform_values(&:to_set)
      end

      strong_memoize_attr :todo_list
    end
  end
end
