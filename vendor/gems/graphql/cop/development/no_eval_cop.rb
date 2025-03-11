# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    class NoEvalCop < RuboCop::Cop::Base
      MSG_TEMPLATE = "Don't use `%{eval_method_name}` which accepts strings and may result evaluating unexpected code. Use `%{exec_method_name}` instead, and pass a block."

      def on_send(node)
        case node.method_name
        when :module_eval, :class_eval, :instance_eval
          message = MSG_TEMPLATE % { eval_method_name: node.method_name, exec_method_name: node.method_name.to_s.sub("eval", "exec").to_sym }
          add_offense node, message: message
        end
      end
    end
  end
end
