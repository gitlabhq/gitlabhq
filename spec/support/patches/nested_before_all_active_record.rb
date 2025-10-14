# frozen_string_literal: true

return unless Gitlab.next_rails?

if Gem::Version.new(TestProf::VERSION) > Gem::Version.new('1.4.4')
  raise 'When upgrading test-prof, evaluate if this patch is still needed'
end

require 'test_prof/before_all/adapters/active_record'

# Fixes a bug in `test-prof` to handle nested before_all blocks
# See https://github.com/test-prof/test-prof/issues/327
module NestedBeforeAllActiveRecord
  def subscribe!
    Thread.current[:before_all_subscription_count] ||= 0
    Thread.current[:before_all_subscription_count] += 1

    return unless Thread.current[:before_all_subscription_count] == 1

    super
  end

  def unsubscribe!
    Thread.current[:before_all_subscription_count] -= 1

    return unless Thread.current[:before_all_subscription_count] == 0

    super
  end
end

TestProf::BeforeAll::Adapters::ActiveRecord.singleton_class.prepend(NestedBeforeAllActiveRecord)
