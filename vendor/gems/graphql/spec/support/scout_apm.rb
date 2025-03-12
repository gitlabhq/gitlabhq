# frozen_string_literal: true
# A stub for the Scout agent, so we can make assertions about how it is used
if defined?(ScoutApm)
  raise "Expected ScoutApm to be undefined, so that we could define a stub for it."
end

class ScoutApm
  TRANSACTION_NAMES = []

  def self.clear_all
    TRANSACTION_NAMES.clear
  end

  module Tracer
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def instrument(type, name, options = {})
        yield
      end
    end
  end

  module Transaction
    def self.rename(name)
      ScoutApm::TRANSACTION_NAMES << name
    end
  end
end
