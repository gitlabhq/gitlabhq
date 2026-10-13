# frozen_string_literal: true

# rspec-mocks checks whether an ancestor already observes a stubbed method by
# creating a recorder for every ancestor, each of which walks its own
# ancestors. That is quadratic in the ancestor count, and our models have 200+
# ancestors. Only ancestors that already have a recorder can be observing, so
# skip the rest.
#
# Remove once https://github.com/rspec/rspec/pull/347 is released.
module RSpec
  module Mocks
    module AnyInstance
      module RecorderAncestorCheck
        private

        def ancestor_is_an_observer?(ancestor, method_name)
          return false if ancestor == @klass

          recorder = ::RSpec::Mocks.space.any_instance_recorder_for(ancestor, true)
          !!recorder&.already_observing?(method_name)
        end
      end
    end
  end
end

RSpec::Mocks::AnyInstance::Recorder.prepend(RSpec::Mocks::AnyInstance::RecorderAncestorCheck)
