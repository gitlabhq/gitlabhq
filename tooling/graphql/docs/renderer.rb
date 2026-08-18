# frozen_string_literal: true

require_relative 'helper'

module Tooling
  module Graphql
    module Docs
      class Renderer
        TEMPLATES_DIR = Rails.root.join('tooling/graphql/docs/templates')

        # Provides a context of helpers and instance variables
        # that templates use.
        class TemplateContext
          include Helper

          def initialize(locals = {})
            locals.each do |key, value|
              instance_variable_set(:"@#{key}", value)
            end
          end

          def get_binding
            binding
          end
        end

        def initialize(template:, locals: {})
          @template = File.join(TEMPLATES_DIR, "#{template}.md.erb")
          raise ArgumentError, "Template not found: #{template}" unless File.exist?(@template)

          @context = TemplateContext.new(locals)
        end

        def execute
          layout = ERB.new(File.read(template), trim_mode: '<>')
          # Render and remove an extra trailing new line
          layout.result(context.get_binding).sub(/\n(?=\Z)/, '')
        end

        private

        attr_reader :template, :context
      end
    end
  end
end
