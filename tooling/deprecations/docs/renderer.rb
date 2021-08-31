# frozen_string_literal: true
require 'erb'

module Deprecations
  module Docs
    module Renderer
      module_function

      def render(**variables)
        template = File.expand_path("data/deprecations/templates/_deprecation_template.md.erb", "#{__dir__}/../../..")

        load_template(template).result_with_hash(variables)
      end

      def load_template(filename)
        ERB.new(File.read(filename), trim_mode: '-')
      end
    end
  end
end
