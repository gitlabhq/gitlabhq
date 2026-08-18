# frozen_string_literal: true

module Docs
  module EventNodoc
    NODOC_FILENAME = 'data/events/.nodoc'

    # Returns an array of path suffixes to exclude from event documentation.
    def self.patterns(root)
      path = File.join(root.to_s, NODOC_FILENAME)

      File.readlines(path).filter_map { |line| line.strip.presence unless line.start_with?('#') }
    rescue Errno::ENOENT
      []
    end

    # Returns true if file_path matches any .nodoc pattern.
    def self.excluded?(file_path, root)
      patterns(root).any? { |pattern| file_path.end_with?(pattern) }
    end
  end
end
