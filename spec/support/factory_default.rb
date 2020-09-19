# frozen_string_literal: true

RSpec.configure do |config|
  config.after do |ex|
    TestProf::FactoryDefault.reset unless ex.metadata[:factory_default] == :keep
  end

  config.after(:all) do
    TestProf::FactoryDefault.reset
  end
end
