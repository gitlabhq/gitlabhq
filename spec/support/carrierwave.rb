CarrierWave.root = 'tmp/tests/uploads'

RSpec.configure do |config|
  config.after(:suite) do
    FileUtils.rm_rf('tmp/tests/uploads')
  end
end
