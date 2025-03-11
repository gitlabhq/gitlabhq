# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    # Make sure no tests are focused, from https://github.com/rubocop-hq/rubocop/issues/3773#issuecomment-420662102
    class NoFocusCop < RuboCop::Cop::Base
      MSG = 'Remove `focus` from tests.'

      def_node_matcher :focused?, <<-MATCHER
        (send nil? :focus)
      MATCHER

      def on_send(node)
        return unless focused?(node)

        add_offense node
      end
    end
  end
end
