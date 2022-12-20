# frozen_string_literal: true

# This patch allows stubbing of prepended methods
# Based on https://github.com/rspec/rspec-mocks/pull/1218

module RSpec
  module Mocks
    module InstanceMethodStasherForPrependedMethods
      private

      def method_owned_by_klass?
        owner = @klass.instance_method(@method).owner
        owner = owner.class unless Module === owner

        owner == @klass ||
          # When `extend self` is used, and not under any instance of
          (owner.singleton_class == @klass && !Mocks.space.any_instance_recorder_for(owner, true)) ||
          !method_defined_on_klass?(owner)
      end
    end
  end
end

module RSpec
  module Mocks
    module MethodDoubleForPrependedMethods
      def restore_original_method
        return show_frozen_warning if object_singleton_class.frozen?
        return unless @method_is_proxied

        remove_method_from_definition_target

        if @method_stasher.method_is_stashed?
          @method_stasher.restore
          restore_original_visibility
        end

        @method_is_proxied = false
      end

      def restore_original_visibility
        method_owner.__send__(@original_visibility, @method_name)
      end

      private

      def method_owner
        @method_owner ||= Object.instance_method(:method).bind_call(object, @method_name).owner
      end
    end
  end
end

RSpec::Mocks::InstanceMethodStasher.prepend(RSpec::Mocks::InstanceMethodStasherForPrependedMethods)
RSpec::Mocks::MethodDouble.prepend(RSpec::Mocks::MethodDoubleForPrependedMethods)
