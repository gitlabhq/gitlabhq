CarrierWave.root = File.expand_path('tmp/tests/uploads', Rails.root)

RSpec.configure do |config|
  config.after(:each) do
    FileUtils.rm_rf(CarrierWave.root)
  end
end
