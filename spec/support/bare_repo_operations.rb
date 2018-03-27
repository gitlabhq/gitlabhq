require 'zlib'

class BareRepoOperations
  # The ID of empty tree.
  # See http://stackoverflow.com/a/40884093/1856239 and https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
  EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'.freeze

  include Gitlab::Popen

  def initialize(path_to_repo)
    @path_to_repo = path_to_repo
  end

  def commit_tree(tree_id, msg, parent: EMPTY_TREE_ID)
    commit_tree_args = ['commit-tree', tree_id, '-m', msg]
    commit_tree_args += ['-p', parent] unless parent == EMPTY_TREE_ID
    commit_id = execute(commit_tree_args)

    commit_id[0]
  end

  # Based on https://stackoverflow.com/a/25556917/1856239
  def commit_file(file, dst_path, branch = 'master')
    head_id = execute(['show', '--format=format:%H', '--no-patch', branch], allow_failure: true)[0] || EMPTY_TREE_ID

    execute(['read-tree', '--empty'])
    execute(['read-tree', head_id])

    blob_id = execute(['hash-object', '--stdin', '-w']) do |stdin|
      stdin.write(file.read)
    end

    execute(['update-index', '--add', '--cacheinfo', '100644', blob_id[0], dst_path])

    tree_id = execute(['write-tree'])

    commit_id = commit_tree(tree_id[0], "Add #{dst_path}", parent: head_id)

    execute(['update-ref', "refs/heads/#{branch}", commit_id])
  end

  private

  def execute(args, allow_failure: false)
    output, status = popen(base_args + args, nil) do |stdin|
      yield stdin if block_given?
    end

    unless status.zero?
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
