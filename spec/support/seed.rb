RSpec.configure do |config|
  config.include SeedHelper, :seed_helper

  config.before(:all, :seed_helper) do
    ensure_seeds
  end
end
