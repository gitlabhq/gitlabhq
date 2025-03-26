# frozen_string_literal: true

# This patches the RSpec class_double, and instance_double, and object_double
# methods to fall back to a normal double if run within the
# fast_spec_helper context.
#
# This allows these methods to still be used in fast_spec_helper specs
# without failing as long as the doubled_class is passed as a String.
#
# It addresses two scenarios:
# 1. When a fast_spec_helper is run with Spring preloader enabled and loaded.
#    Normally, this case will fail because it attempts to validate the
#    mocked class/instance methods.
# 2. Also allows the methods to behave with normal validating behavior if
#    a fast_spec_helper spec is run within a spec_helper context, which
#    will happen if a test suite containing both fast_spec_helper and normal
#    spec_helper files happens to load the normal spec_helper first.
#
# Since spec_helper contains logic to prevent it from ever loading if
# fast_spec_helper is already loaded, there is no chance of this
# module ever being loaded or used in the normal spec_helper context - its
# only required from fast_spec_helper.

if defined?(FastSpecHelper) # Only load this patch when executing in fast_spec_helper context!
  module RSpec
    module Mocks
      module ExampleMethods
        def class_double(doubled_class, *args)
          call_double(doubled_class, *args)
        end

        def instance_double(doubled_class, *args)
          call_double(doubled_class, *args)
        end

        private

        def call_double(name, *args)
          # If the first element of args is a String or Symbol, it is the name of the
          # double, we need to use it instead of the doubled_class as the name,
          # because #double expects only `name` and `stubs` as arguments.
          possible_name = args.first
          name = args.shift if String === possible_name || Symbol === possible_name

          double(name, *args) # rubocop:disable RSpec/VerifiedDoubles -- This is intentional - read the comments above.
        end
      end
    end
  end
end
