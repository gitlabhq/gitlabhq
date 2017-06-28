RSpec.configure do |config|
  config.before(:each, :repository) do
    TestEnv.clean_test_path
  end
end
