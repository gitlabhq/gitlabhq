# frozen_string_literal: true

require 'open3'

module Quality
  # Database dictionary entries added since `base_ref`. Callers decide which of those paths name a
  # real table - `db/docs/` also holds views, deleted tables and background migrations - so this
  # only answers "what was added", which is the part that needs git.
  class AddedTables
    UnreadableBaseRef = Class.new(StandardError)

    DICTIONARY_DIRS = %w[db/docs ee/db/docs].freeze

    def initialize(base_ref, repository_path: File.expand_path('../..', __dir__))
      @base_ref = base_ref
      @repository_path = repository_path
    end

    def entry_names
      # CI clones are shallow (GIT_DEPTH), so the base ref is not always present. Say so rather
      # than returning nothing, which would look identical to "this diff adds no entries".
      raise UnreadableBaseRef, "base ref '#{base_ref}' is not readable (shallow clone?)" unless base_ref_readable?

      added_files.filter_map { |path| File.basename(path, '.yml') if path.end_with?('.yml') }
    end

    private

    attr_reader :base_ref, :repository_path

    def base_ref_readable?
      _, status = git('rev-parse', '--verify', '--quiet', "#{base_ref}^{commit}")
      status&.success?
    end

    def added_files
      output, status = git(*diff_arguments)
      return [] unless status&.success?

      output.split("\n").map(&:strip).reject(&:empty?)
    end

    def git(*arguments)
      Open3.capture2('git', *arguments, chdir: repository_path)
    rescue SystemCallError
      [nil, nil]
    end

    def diff_arguments
      %W[diff --diff-filter=A --name-only #{base_ref}...HEAD --] + DICTIONARY_DIRS
    end
  end
end
