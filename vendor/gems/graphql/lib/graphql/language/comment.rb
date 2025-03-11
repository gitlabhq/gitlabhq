# frozen_string_literal: true
module GraphQL
  module Language
    module Comment
      def self.print(str, indent: '')
        lines = str.split("\n").map do |line|
          comment_str = "".dup
          comment_str << indent
          comment_str << "# "
          comment_str << line
          comment_str.rstrip
        end

        lines.join("\n") + "\n"
      end
    end
  end
end
