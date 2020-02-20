# frozen_string_literal: true

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

# Use FactoryBot 4.x behavior:
# https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#associations
FactoryBot.use_parent_strategy = false
