# frozen_string_literal: true

require 'fileutils'

module Tooling
  module Helpers
    module FileHandler
      def read_array_from_file(file)
        FileUtils.touch file

        File.read(file).split(' ')
      end

      def write_array_to_file(file, content_array)
        FileUtils.touch file

        output_content = (File.read(file).split(' ') + content_array).join(' ')

        File.write(file, output_content)
      end
    end
  end
end
