module RepoHelpers
  extend self

  # Text file in repo
  #
  # Ex.
  #
  #   # Get object
  #   blob = RepoHelpers.text_blob
  #
  #   blob.path # => 'files/js/commit.js.coffee'
  #   blob.data # => 'class Commit...'
  #
  def sample_blob
    OpenStruct.new(
      oid: '5f53439ca4b009096571d3c8bc3d09d30e7431b3',
      path: "files/js/commit.js.coffee",
      data: <<eos
class Commit
  constructor: ->
    $('.files .diff-file').each ->
      new CommitFile(this)

@Commit = Commit
eos
    )
  end

  def sample_commit
    OpenStruct.new(
      id: "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
      parent_id: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9',
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      files_changed_count: 2,
      line_code: '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_14',
      line_code_path: 'files/ruby/popen.rb',
      del_line_code: '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_13_13',
      message: <<eos
Change some files
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
eos
    )
  end

  def another_sample_commit
    OpenStruct.new(
      id: "e56497bb5f03a90a51293fc6d516788730953899",
      parent_id: '4cd80ccab63c82b4bad16faa5193fbd2aa06df40',
      author_full_name: "Sytse Sijbrandij",
      author_email: "sytse@gitlab.com",
      files_changed_count: 1,
      message: <<eos
Add directory structure for tree_helper spec

This directory structure is needed for a testing the method flatten_tree(tree) in the TreeHelper module

See [merge request #275](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/275#note_732774)

See merge request !2
eos
    )
  end

  def sample_big_commit
    OpenStruct.new(
      id: "913c66a37b4a45b9769037c55c2d238bd0942d2e",
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      message: <<eos
Files, encoding and much more
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
eos
    )
  end

  def sample_image_commit
    OpenStruct.new(
      id: "2f63565e7aac07bcdadb654e253078b727143ec4",
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      old_blob_id: '33f3729a45c02fc67d00adb1b8bca394b0e761d9',
      new_blob_id: '2f63565e7aac07bcdadb654e253078b727143ec4',
      message: <<eos
Modified image
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
eos
    )
  end

  def sample_compare
    changes = [
      {
        line_code: 'a5cc2925ca8258af241be7e5b0381edf30266302_20_20',
        file_path: '.gitignore'
      },
      {
        line_code: '7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44_4_6',
        file_path: '.gitmodules'
      }
    ]

    commits = %w(
      5937ac0a7beb003549fc5fd26fc247adbce4a52e
      570e7b2abdd848b95f2f578043fc23bd6f6fd24d
      6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9
      d14d6c0abdd253381df51a723d58691b2ee1ab08
      c1acaa58bbcbc3eafe538cb8274ba387047b69f8
    ).reverse # last commit is recent one

    OpenStruct.new(
      source_branch: 'master',
      target_branch: 'feature',
      changes: changes,
      commits: commits
    )
  end
end
