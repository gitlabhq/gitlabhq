# frozen_string_literal: true

module Tooling
  module Debug
    class << self
      attr_accessor :debug
    end

    def print(*args)
      return unless Tooling::Debug.debug

      super(*args)
    end

    def puts(*args)
      return unless Tooling::Debug.debug

      super(*args)
    end
  end
end
