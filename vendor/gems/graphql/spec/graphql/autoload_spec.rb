# frozen_string_literal: true

require "spec_helper"
require "open3"

describe GraphQL::Autoload do
  module LazyModule
    extend GraphQL::Autoload
    autoload(:LazyClass, "fixtures/lazy_module/lazy_class")
  end

  module EagerModule
    extend GraphQL::Autoload
    autoload(:EagerClass, "fixtures/eager_module/eager_class")
    autoload(:OtherEagerClass, "fixtures/eager_module/other_eager_class")
    autoload(:NestedEagerModule, "fixtures/eager_module/nested_eager_module")

    def self.eager_load!
      super

      NestedEagerModule.eager_load!
    end
  end

  describe "#autoload" do
    it "sets autoload" do
      assert LazyModule.const_defined?(:LazyClass)
      assert_equal("fixtures/lazy_module/lazy_class", LazyModule.autoload?(:LazyClass))
      LazyModule::LazyClass
      assert_nil(LazyModule.autoload?(:LazyClass))
    end
  end

  describe "#eager_load!" do
    it "eagerly loads autoload entries" do
      assert EagerModule.autoload?(:EagerClass)
      assert EagerModule.autoload?(:OtherEagerClass)
      assert EagerModule.autoload?(:NestedEagerModule)

      EagerModule.eager_load!

      assert_nil(EagerModule.autoload?(:EagerClass))
      assert_nil(EagerModule.autoload?(:OtherEagerClass))
      assert_nil(EagerModule.autoload?(:NestedEagerModule))
      assert_nil(EagerModule::NestedEagerModule.autoload?(:NestedEagerClass))
      assert EagerModule::NestedEagerModule::NestedEagerClass
    end
  end

  describe "loading nested files in the repo" do
    it "can load them individually" do
      files_to_load = Dir.glob("lib/**/tracing/*.rb")
      assert_equal 28, files_to_load.size, "It found all the expected files"
      files_to_load.each do |file|
        require_path = file.sub("lib/", "").sub(".rb", "")
        stderr_and_stdout, _status = Open3.capture2e("ruby -Ilib -e 'require \"#{require_path}\"'")
        assert_equal "", stderr_and_stdout, "It loads #{require_path.inspect} in isolation"
        stderr_and_stdout, _status = Open3.capture2e("ruby -Ilib -e 'require \"graphql\"; require \"#{require_path}\"'")
        assert_equal "", stderr_and_stdout, "It loads #{require_path.inspect} after loading graphql"
      end
    end
  end
end
