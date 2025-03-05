# frozen_string_literal: true

require_relative 'helper'

module Tooling
  module DastVariables
    module Docs
      class Renderer
        include Tooling::DastVariables::Docs::Helper

        attr_reader :schema

        def initialize(output_file:, template:)
          @output_file = output_file
          @template = template
          @layout = Haml::Engine.new(File.read(template))
        end

        def contents
          # Render and remove an extra trailing new line
          @contents ||= @layout.render(self).sub!(/\n(?=\Z)/, '')
        end

        def write
          File.write(@output_file, contents)
        end
      end
    end
  end
end
