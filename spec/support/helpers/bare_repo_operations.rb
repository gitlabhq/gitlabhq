# frozen_string_literal: true

require 'zlib'

class BareRepoOperations
  include Gitlab::Popen

  def initialize(path_to_repo)
    @path_to_repo = path_to_repo
  end

  def commit_tree(tree_id, msg, parent: Gitlab::Git::EMPTY_TREE_ID)
    commit_tree_args = ['commit-tree', tree_id, '-m', msg]
    commit_tree_args += ['-p', parent] unless parent == Gitlab::Git::EMPTY_TREE_ID
    commit_id = execute(commit_tree_args)

    commit_id[0]
  end

  private

  def execute(args, allow_failure: false)
    output, status = popen(base_args + args, nil) do |stdin|
      yield stdin if block_given?
    end

    unless status == 0
      if allow_failure
        return []
      else
        raise "Got a non-zero exit code while calling out `#{args.join(' ')}`: #{output}"
      end
    end

    output.split("\n")
  end

  def base_args
    [
      Gitlab.config.git.bin_path,
      "--git-dir=#{@path_to_repo}"
    ]
  end
end
