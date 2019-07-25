# frozen_string_literal: true

RSpec.configure do |config|
  config.after do
    BatchLoader::Executor.clear_current
  end
end
