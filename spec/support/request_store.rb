RSpec.configure do |config|
  config.before(:each) do
    RequestStore.clear!
  end
end
