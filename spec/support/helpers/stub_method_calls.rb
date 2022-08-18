# frozen_string_literal: true

# Used to stud methods for factories where we can't
# use rspec-mocks.
#
# Examples:
#   stub_method(user, :some_method) { |var1, var2| var1 + var2 }
#   stub_method(user, :some_method) { true }
#   stub_method(user, :some_method) => nil
#   stub_method(user, :some_method) do |*args|
#     true
#   end
#
#  restore_original_method(user, :some_method)
#  restore_original_methods(user)
#
module StubMethodCalls
  AlreadyImplementedError = Class.new(StandardError)

  def stub_method(object, method, &block)
    Backup.stub_method(object, method, &block)
  end

  def restore_original_method(object, method)
    Backup.restore_method(object, method)
  end

  def restore_original_methods(object)
    Backup.stubbed_methods(object).each_key { |method, backed_up_method| restore_original_method(object, method) }
  end

  module Backup
    def self.stubbed_methods(object)
      return {} unless object.respond_to?(:_stubbed_methods)

      object._stubbed_methods
    end

    def self.backup_method(object, method)
      backed_up_methods = stubbed_methods(object)
      backed_up_methods[method] = object.respond_to?(method) ? object.method(method) : nil

      object.define_singleton_method(:_stubbed_methods) { backed_up_methods }
    end

    def self.stub_method(object, method, &block)
      raise ArgumentError, "Block is required" unless block

      backup_method(object, method) unless backed_up_method?(object, method)
      object.define_singleton_method(method, &block)
    end

    def self.restore_method(object, method)
      raise NotImplementedError, "#{method} has not been stubbed on #{object}" unless backed_up_method?(object, method)

      object.singleton_class.remove_method(method)
      backed_up_method = stubbed_methods(object)[method]

      object.define_singleton_method(method, backed_up_method) if backed_up_method
    end

    def self.backed_up_method?(object, method)
      stubbed_methods(object).key?(method)
    end
  end
end
