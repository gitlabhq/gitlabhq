module ValidCommit
  ID = "570e7b2abdd848b95f2f578043fc23bd6f6fd24d"
  MESSAGE = <<eos
Change some files
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
eos
  AUTHOR_FULL_NAME = "Dmitriy Zaporozhets"
  AUTHOR_EMAIL = "dmitriy.zaporozhets@gmail.com"

  FILES = [".foreman", ".gitignore", ".rails_footnotes", ".rspec", ".travis.yml", "CHANGELOG", "Gemfile", "Gemfile.lock", "LICENSE", "Procfile", "Procfile.production", "README.md", "Rakefile", "VERSION", "app", "config.ru", "config", "db", "doc", "lib", "log", "public", "resque.sh", "script", "spec", "vendor"]
  FILES_COUNT = 26

  C_FILE_PATH = "app/models"
  C_FILES = [".gitkeep", "ability.rb", "commit.rb", "issue.rb", "key.rb", "mailer_observer.rb", "merge_request.rb", "note.rb", "project.rb", "protected_branch.rb", "repository.rb", "snippet.rb", "tree.rb", "user.rb", "users_project.rb", "web_hook.rb", "wiki.rb"]

  BLOB_FILE = <<eos
class Commit
  constructor: ->
    $('.files .diff-file').each ->
      new CommitFile(this)

@Commit = Commit
eos

  BLOB_FILE_PATH = "files/js/commit.js.coffee"
end

