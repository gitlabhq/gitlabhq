# frozen_string_literal: true

require_relative 'docs/compiler'

module Tooling
  module Graphql
    module Docs
      class << self
        def compile!
          FileUtils.mkdir_p(Compiler::OUTPUT_DIR)

          Compiler.new.execute.each do |page|
            File.write(page.filename, page.doc)
          end
        end

        def stale?
          Compiler.new.execute.any? do |page|
            File.read(page.filename) != page.doc
          end
        end
      end
    end
  end
end
