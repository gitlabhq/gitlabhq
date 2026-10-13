# frozen_string_literal: true

require 'open3'

module Quality
  # Database dictionary entries added since `base_ref`, from the dictionary roots only. Callers
  # decide which of those names is a table, so this only answers "what was added", which is the
  # part that needs git.
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

      # One entry can be added to both dictionary roots, and reporting it twice would make the
      # caller's count disagree with the findings it prints.
      added_files.filter_map { |path| File.basename(path, '.yml') if path.end_with?('.yml') }.uniq
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
      # `:(glob)` stops `*` crossing a `/`, so subdirectories such as `db/docs/data_retention/`
      # are excluded. A file there is named after the table it describes, so without this the
      # dictionary resolves it as a real table entry and the caller reads it as newly added.
      pathspecs = DICTIONARY_DIRS.map { |dir| ":(glob)#{dir}/*.yml" }

      %W[diff --diff-filter=A --name-only #{base_ref}...HEAD --] + pathspecs
    end
  end
end
