# frozen_string_literal: true

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

# Patching FactoryBot to allow stubbing non AR models
# See https://github.com/thoughtbot/factory_bot/pull/1466
module Gitlab
  module FactoryBotStubPatch
    def has_settable_id?(result_instance)
      result_instance.class.respond_to?(:primary_key) &&
        result_instance.class.primary_key
    end
  end
end

FactoryBot::Strategy::Stub.prepend(Gitlab::FactoryBotStubPatch)
