# frozen_string_literal: true

CarrierWave.root = File.expand_path('tmp/tests/public', Rails.root)

RSpec.configure do |config|
  config.after do
    FileUtils.rm_rf(CarrierWave.root)
  end
end
