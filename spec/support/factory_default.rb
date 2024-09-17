# frozen_string_literal: true

module Gitlab
  module FreezeFactoryDefault
    def set_factory_default(name, obj, preserve_traits: nil)
      obj.freeze unless obj.frozen?

      super
    end
  end
end

TestProf::FactoryDefault::FactoryBotPatch::SyntaxExt.prepend Gitlab::FreezeFactoryDefault

RSpec.configure do |config|
  config.after do |ex|
    TestProf::FactoryDefault.reset unless ex.metadata[:factory_default] == :keep
  end

  config.after(:all) do
    TestProf::FactoryDefault.reset
  end
end
