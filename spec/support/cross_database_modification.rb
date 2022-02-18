# frozen_string_literal: true

RSpec.configure do |config|
  config.after do |example|
    [::ApplicationRecord, ::Ci::ApplicationRecord].each do |base_class|
      base_class.gitlab_transactions_stack.clear if base_class.respond_to?(:gitlab_transactions_stack)
    end
  end
end
