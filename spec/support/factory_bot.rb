# frozen_string_literal: true

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods

  # FactoryBot doesn't allow yet to add a helper that can be used in factories
  # While the fixture_file_upload helper is reasonable to be used there:
  #
  # https://github.com/thoughtbot/factory_bot/issues/564#issuecomment-389491577
  def fixture_file_upload(*args, **kwargs)
    Rack::Test::UploadedFile.new(*args, **kwargs)
  end
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
