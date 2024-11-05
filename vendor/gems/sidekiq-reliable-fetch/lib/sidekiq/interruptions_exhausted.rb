# frozen_string_literal: true

module Sidekiq
  module InterruptionsExhausted
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sidekiq_interruptions_exhausted(&block)
        @interruptions_exhausted_block = block
      end

      def interruptions_exhausted_block
        @interruptions_exhausted_block
      end
    end
  end
end
