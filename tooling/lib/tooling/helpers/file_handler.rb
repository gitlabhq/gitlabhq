# frozen_string_literal: true

require 'fileutils'

module Tooling
  module Helpers
    module FileHandler
      def read_array_from_file(file)
        FileUtils.touch file

        File.read(file).split(' ')
      end

      def write_array_to_file(file, content_array, append: true)
        FileUtils.touch file

        # We sort the array to make it easier to read the output file
        content_array.sort!

        output_content =
          if append
            [File.read(file), *content_array].join(' ').lstrip
          else
            content_array.join(' ')
          end

        File.write(file, output_content)
      end
    end
  end
end
